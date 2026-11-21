"""End-to-end integration tests against live Logstash, Elasticsearch, and Kibana."""

from __future__ import annotations

import hashlib
import os
import time
from pathlib import Path

import pytest
import requests

from xml_insight_lab.models import (
    ERRORS_INDEX,
    MESSAGES_INDEX,
    PLAN_STATUS_INDEX,
    RUNS_INDEX,
    STEPS_INDEX,
    SUITES_INDEX,
    TESTCASES_INDEX,
)
from xml_insight_lab.uploader import build_envelope, post_envelope_with_retry
from xml_insight_lab.verifier import get_index_count, refresh_indices

ES_URL = os.environ.get("ES_URL", "http://127.0.0.1:9200").rstrip("/")
LOGSTASH_URL = os.environ.get("LOGSTASH_URL", "http://127.0.0.1:8080").rstrip("/")
KIBANA_URL = os.environ.get("KIBANA_URL", "http://127.0.0.1:5601").rstrip("/")


def _stack_available() -> bool:
    try:
        return requests.get(f"{ES_URL}/_cluster/health", timeout=2.0).status_code == 200
    except Exception:
        return False


pytestmark = pytest.mark.skipif(not _stack_available(), reason="Live Elastic Stack is not running")


def _sample_xml_path() -> Path:
    ws = Path(os.environ.get("WORKSPACE_DIR", Path(__file__).resolve().parents[2]))
    return ws / "examples" / "sample-report-v1.xml"


def _sample_run_id() -> str:
    sha = hashlib.sha256(_sample_xml_path().read_bytes()).hexdigest()
    return f"imp-{sha[:16]}"


def _wait_for_doc(index: str, doc_id: str, timeout: float = 20.0) -> dict:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        refresh_indices(ES_URL, (index,))
        resp = requests.get(f"{ES_URL}/{index}/_doc/{doc_id}", timeout=5.0)
        if resp.status_code == 200:
            return resp.json()
        time.sleep(0.5)
    raise AssertionError(f"Document {doc_id} did not appear in {index} within {timeout}s")


def test_canonical_sample_report_exact_counts_and_rules() -> None:
    run_id = _sample_run_id()
    run_doc = _wait_for_doc(RUNS_INDEX, run_id)["_source"]

    # 1 Report, 3 Suites, 5 regular TestCases (2 PASSED, 3 FAILED), 1 separate Deinit PASSED
    assert run_doc["suite_count"] == 3
    assert run_doc["suite_names"] == ["Workspace", "Content", "Settings"]
    assert run_doc["regular_tc_total"] == 5
    assert run_doc["regular_tc_passed"] == 2
    assert run_doc["regular_tc_failed"] == 3
    assert run_doc["deinit_tc_total"] == 1
    assert run_doc["deinit_tc_passed"] == 1
    # Init has no explicit result -> UNKNOWN (never invented!)
    assert run_doc["init_normalized_result"] == "UNKNOWN"
    assert "init_source_result" not in run_doc

    # Timezone conversion: Europe/Berlin 2026-11-17T01:00:00 -> 2026-11-17T00:00:00.000Z
    assert run_doc["timezone_assumed"] == "Europe/Berlin"
    assert run_doc["timezone_status"] == "assumed_local"
    assert run_doc["started_at"] == "2026-11-17T00:00:00.000Z"

    # Unknown param preserved without dynamic mapping fields; SoftwareVersion extracted
    assert run_doc["software"]["version"] == "1.4.0"
    assert {"name": "TargetRegion", "value": "eu-demo"} in run_doc["init_params"]

    # Both repeated Emit_Signal steps in TC_WORKSPACE_002 preserved separately
    refresh_indices(ES_URL, (STEPS_INDEX, TESTCASES_INDEX, MESSAGES_INDEX))
    steps_resp = requests.post(
        f"{ES_URL}/{STEPS_INDEX}/_search",
        json={
            "query": {
                "bool": {
                    "must": [
                        {"term": {"run.id": run_id}},
                        {"term": {"test_case.name": "TC_WORKSPACE_002"}},
                        {"term": {"step.name": "Emit_Signal"}},
                    ]
                }
            },
            "sort": [{"step.sequence": "asc"}],
        },
        timeout=5.0,
    ).json()
    hits = steps_resp["hits"]["hits"]
    assert len(hits) == 2
    assert [h["_source"]["step"]["sequence"] for h in hits] == [1, 2]
    assert [h["_source"]["normalized_result"] for h in hits] == ["PASSED", "FAILED"]

    # TC_SETTINGS_001 has no duration -> duration_ms omitted, not invented
    tc_settings = requests.post(
        f"{ES_URL}/{TESTCASES_INDEX}/_search",
        json={"query": {"bool": {"must": [{"term": {"run.id": run_id}}, {"term": {"test_case.name": "TC_SETTINGS_001"}}]}}},
        timeout=5.0,
    ).json()["hits"]["hits"][0]["_source"]
    assert "duration_ms" not in tc_settings

    # Message without level has no invented level
    msgs = requests.post(
        f"{ES_URL}/{MESSAGES_INDEX}/_search",
        json={"size": 50, "query": {"term": {"run.id": run_id}}},
        timeout=5.0,
    ).json()["hits"]["hits"]
    levelless = [m["_source"] for m in msgs if "without explicit level" in m["_source"]["original_text"]]
    assert len(levelless) == 1
    assert "level" not in levelless[0]

    # Multiple <errors><msg> in TC_CONTENT_001 do not multiply TC failure count
    tc_content1 = requests.post(
        f"{ES_URL}/{TESTCASES_INDEX}/_search",
        json={"query": {"bool": {"must": [{"term": {"run.id": run_id}}, {"term": {"test_case.name": "TC_CONTENT_001"}}]}}},
        timeout=5.0,
    ).json()["hits"]["hits"][0]["_source"]
    assert tc_content1["error_msg_count"] == 2
    assert "IMG_CAPTURE_FAILED" in tc_content1["extracted_error_codes"]


def test_extra_group_without_testcases_preserved() -> None:
    refresh_indices(ES_URL, (RUNS_INDEX,))
    resp = requests.post(
        f"{ES_URL}/{RUNS_INDEX}/_search",
        json={"query": {"term": {"extra_group_names": "CustomDiagnostics"}}},
        timeout=5.0,
    ).json()
    assert len(resp["hits"]["hits"]) >= 1


def test_invalid_fixtures_and_nonexistent_dst_rejected() -> None:
    refresh_indices(ES_URL, (ERRORS_INDEX,))
    assert get_index_count(ES_URL, ERRORS_INDEX) >= 4
    err_resp = requests.post(
        f"{ES_URL}/{ERRORS_INDEX}/_search",
        json={"size": 20, "query": {"match_all": {}}},
        timeout=5.0,
    ).json()
    codes = {h["_source"]["error_code"] for h in err_resp["hits"]["hits"]}
    assert "INVALID_REPORT_TIMESTAMP" in codes
    assert "DTD_OR_ENTITY_FORBIDDEN" in codes
    assert "NEGATIVE_REPORT_DURATION" in codes


def test_reimport_sample_without_duplicates() -> None:
    refresh_indices(ES_URL)
    runs_before = get_index_count(ES_URL, RUNS_INDEX)
    suites_before = get_index_count(ES_URL, SUITES_INDEX)
    tcs_before = get_index_count(ES_URL, TESTCASES_INDEX)
    steps_before = get_index_count(ES_URL, STEPS_INDEX)

    with requests.Session() as session:
        post_envelope_with_retry(session, LOGSTASH_URL, build_envelope(_sample_xml_path()))
    time.sleep(2.0)
    refresh_indices(ES_URL)

    assert get_index_count(ES_URL, RUNS_INDEX) == runs_before
    assert get_index_count(ES_URL, SUITES_INDEX) == suites_before
    assert get_index_count(ES_URL, TESTCASES_INDEX) == tcs_before
    assert get_index_count(ES_URL, STEPS_INDEX) == steps_before


def test_plan_reconciliation_missing_and_partial_suites() -> None:
    refresh_indices(ES_URL, (PLAN_STATUS_INDEX,))
    resp = requests.post(
        f"{ES_URL}/{PLAN_STATUS_INDEX}/_search",
        json={
            "size": 0,
            "aggs": {
                "receipt": {"terms": {"field": "receipt_status"}},
                "completeness": {"terms": {"field": "suite_completeness"}},
            },
        },
        timeout=5.0,
    ).json()["aggregations"]
    rec = {b["key"]: b["doc_count"] for b in resp["receipt"]["buckets"]}
    comp = {b["key"]: b["doc_count"] for b in resp["completeness"]["buckets"]}
    assert rec.get("MISSING", 0) >= 1
    assert comp.get("PARTIAL", 0) >= 1


def test_kibana_dashboards_provisioned() -> None:
    for did in (
        "xml-insight-nightly-overview",
        "xml-insight-suite-overview",
        "xml-insight-run-details",
        "xml-insight-test-details",
        "xml-insight-error-classification",
    ):
        assert requests.get(f"{KIBANA_URL}/api/saved_objects/dashboard/{did}", timeout=5.0).status_code == 200


def test_config_driven_error_mapping_and_deduplication() -> None:
    refresh_indices(ES_URL, (TESTCASES_INDEX, MESSAGES_INDEX, STEPS_INDEX))

    # 1. Verify all 4 dispositions exist and original results are preserved
    agg_resp = requests.post(
        f"{ES_URL}/{TESTCASES_INDEX}/_search",
        json={
            "size": 0,
            "aggs": {
                "dispositions": {"terms": {"field": "error_mapping.disposition"}},
                "categories": {"terms": {"field": "error_mapping.category"}},
            },
        },
        timeout=5.0,
    ).json()["aggregations"]
    dispositions = {b["key"]: b["doc_count"] for b in agg_resp["dispositions"]["buckets"]}
    categories = {b["key"]: b["doc_count"] for b in agg_resp["categories"]["buckets"]}

    assert dispositions.get("RELEVANT", 0) >= 1
    assert dispositions.get("UNCLASSIFIED", 0) >= 1
    assert categories.get("TIMEOUT", 0) >= 1
    assert categories.get("CAPTURE_ERROR", 0) >= 1
    assert categories.get("COMMUNICATION", 0) >= 1
    assert categories.get("DATA_INTEGRITY", 0) >= 1
    assert categories.get("ASSERTION_FAILURE", 0) >= 1
    assert categories.get("UNKNOWN", 0) >= 1

    # 2. Verify KNOWN_ISSUE / IGNORED on messages do not overwrite original test results
    msg_agg = requests.post(
        f"{ES_URL}/{MESSAGES_INDEX}/_search",
        json={"size": 0, "aggs": {"dispositions": {"terms": {"field": "error_mapping.disposition"}}}},
        timeout=5.0,
    ).json()["aggregations"]
    msg_disp = {b["key"]: b["doc_count"] for b in msg_agg["dispositions"]["buckets"]}
    assert msg_disp.get("KNOWN_ISSUE", 0) >= 1
    assert msg_disp.get("IGNORED", 0) >= 1

    # 3. Multi-error TestCase on anchor run: deduplicated fault_count == 2 (UI_TIMEOUT + SYN_CONN_DROPPED)
    multi = requests.post(
        f"{ES_URL}/{TESTCASES_INDEX}/_search",
        json={
            "query": {
                "bool": {
                    "must": [
                        {"term": {"test_bench.id": "lab-01"}},
                        {"term": {"test_case.name": "TC_WORKSPACE_Signal"}},
                        {"term": {"normalized_result": "FAILED"}},
                        {"term": {"error_mapping.matched_rule_ids": "ERR_CONN_DROPPED"}},
                    ]
                }
            }
        },
        timeout=5.0,
    ).json()["hits"]["hits"]
    assert len(multi) >= 1
    src = multi[0]["_source"]
    assert src["source_result"] == "FAILED"
    assert src["normalized_result"] == "FAILED"
    assert src["error_mapping"]["rule_id"] == "ERR_UI_TIMEOUT"
    assert set(src["error_mapping"]["matched_rule_ids"]) == {"ERR_UI_TIMEOUT", "ERR_UI_TIMEOUT_TEXT", "ERR_CONN_DROPPED"}
    assert src["fault_count"] == 2

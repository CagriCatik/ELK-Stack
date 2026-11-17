"""Campaign plan reconciliation and previous-run error trend analysis."""

from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import requests
import yaml

from .models import ERRORS_INDEX, PLAN_STATUS_INDEX, RUNS_INDEX, TESTCASES_INDEX


def parse_utc(ts: str) -> datetime:
    return datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone(timezone.utc)


def fmt_utc(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"


def reconcile_slot(
    slot: dict[str, Any],
    campaign_id: str,
    valid_runs_by_slot: dict[str, dict[str, Any]],
    invalid_errors_by_slot: dict[str, dict[str, Any]],
    evaluated_at: datetime,
) -> dict[str, Any]:
    """Reconcile expected report AND expected suites within that report."""
    slot_id = str(slot["execution_slot_id"])
    expected_start = parse_utc(str(slot["expected_started_at"]))
    deadline_at = parse_utc(str(slot["deadline_at"]))
    expected_suites = [str(s) for s in slot.get("expected_suites", [])]

    valid_run = valid_runs_by_slot.get(slot_id)
    invalid_err = invalid_errors_by_slot.get(slot_id)

    if valid_run is not None:
        received_ts = parse_utc(str(valid_run.get("started_at") or valid_run["ingested_at"]))
        receipt_status = "RECEIVED"
        report_validity = "VALID"
        is_late = received_ts > deadline_at
        matched_run_id = valid_run["run"]["id"]
        run_result = valid_run.get("normalized_result")
        received_at = fmt_utc(received_ts)

        received_suites = [str(s) for s in valid_run.get("suite_names", [])]
        missing_suites = [s for s in expected_suites if s not in received_suites]
        suite_completeness = "PARTIAL" if missing_suites else "COMPLETE"
    elif invalid_err is not None:
        received_ts = parse_utc(str(invalid_err["ingested_at"]))
        receipt_status = "RECEIVED"
        report_validity = "INVALID"
        is_late = received_ts > deadline_at
        matched_run_id = invalid_err.get("run", {}).get("id")
        run_result = None
        received_at = fmt_utc(received_ts)
        received_suites = []
        missing_suites = expected_suites
        suite_completeness = "NONE"
    elif evaluated_at > deadline_at:
        receipt_status = "MISSING"
        report_validity = "NONE"
        is_late = False
        matched_run_id = None
        run_result = None
        received_at = None
        received_suites = []
        missing_suites = expected_suites
        suite_completeness = "NONE"
    else:
        receipt_status = "PENDING"
        report_validity = "NONE"
        is_late = False
        matched_run_id = None
        run_result = None
        received_at = None
        received_suites = []
        missing_suites = expected_suites
        suite_completeness = "NONE"

    doc: dict[str, Any] = {
        "@timestamp": fmt_utc(expected_start),
        "doc_type": "plan_status",
        "synthetic": True,
        "execution_slot_id": slot_id,
        "campaign": {"id": campaign_id},
        "test_bench": slot["test_bench"],
        "project": slot.get("project", "SampleProject"),
        "expected_suites": expected_suites,
        "received_suites": received_suites,
        "missing_suites": missing_suites,
        "suite_completeness": suite_completeness,
        "expected_started_at": fmt_utc(expected_start),
        "deadline_at": fmt_utc(deadline_at),
        "evaluated_at": fmt_utc(evaluated_at),
        "receipt_status": receipt_status,
        "is_late": is_late,
        "report_validity": report_validity,
    }
    if matched_run_id is not None:
        doc["matched_run_id"] = matched_run_id
    if run_result is not None:
        doc["run_result"] = run_result
    if received_at is not None:
        doc["received_at"] = received_at
    return doc


def _fetch_all_hits(es_url: str, index_name: str) -> list[dict[str, Any]]:
    resp = requests.post(
        f"{es_url.rstrip('/')}/{index_name}/_search",
        json={"size": 2000, "query": {"match_all": {}}},
        timeout=10.0,
    )
    if resp.status_code == 404:
        return []
    resp.raise_for_status()
    return resp.json()["hits"]["hits"]


def _compute_error_trends(es_url: str) -> dict[str, int]:
    """Compare each final-attempt testCase against the previous run on the same (bench, suite, testCase)."""
    hits = _fetch_all_hits(es_url, TESTCASES_INDEX)
    regular_finals = [
        h for h in hits
        if h["_source"].get("phase") == "suite" and h["_source"].get("test_case", {}).get("is_final_attempt", True)
    ]
    regular_finals.sort(key=lambda h: h["_source"].get("@timestamp", ""))

    prev_status: dict[tuple[str, str, str], str] = {}
    trend_counts = {"NEW": 0, "RECURRING": 0, "FIXED": 0, "NONE": 0}
    base = es_url.rstrip("/")

    with requests.Session() as session:
        for h in regular_finals:
            src = h["_source"]
            key = (
                src["test_bench"]["id"],
                src["suite"]["name"],
                src["test_case"]["name"],
            )
            cur = src["normalized_result"]
            prev = prev_status.get(key)

            if cur in ("FAILED", "ERROR"):
                trend = "RECURRING" if prev in ("FAILED", "ERROR") else "NEW"
            elif cur == "PASSED" and prev in ("FAILED", "ERROR"):
                trend = "FIXED"
            else:
                trend = "NONE"

            prev_status[key] = cur
            trend_counts[trend] += 1
            session.post(
                f"{base}/{TESTCASES_INDEX}/_update/{h['_id']}",
                json={"doc": {"error_trend": trend}},
                timeout=5.0,
            ).raise_for_status()

    requests.post(f"{base}/{TESTCASES_INDEX}/_refresh", timeout=5.0)
    return trend_counts


def reconcile_plan(
    plan_path: Path,
    es_url: str,
    evaluated_at: datetime | None = None,
) -> dict[str, Any]:
    plan = yaml.safe_load(plan_path.read_text(encoding="utf-8"))
    eval_dt = evaluated_at or datetime.now(timezone.utc)

    runs = [h["_source"] for h in _fetch_all_hits(es_url, RUNS_INDEX)]
    errors = [h["_source"] for h in _fetch_all_hits(es_url, ERRORS_INDEX)]

    valid_by_slot = {str(r["execution_slot_id"]): r for r in runs if r.get("execution_slot_id")}
    errors_by_slot = {str(e["execution_slot_id"]): e for e in errors if e.get("execution_slot_id")}

    summary = {"RECEIVED": 0, "MISSING": 0, "PENDING": 0, "PARTIAL": 0, "INVALID": 0, "LATE": 0}
    base = es_url.rstrip("/")

    with requests.Session() as session:
        for campaign in plan.get("campaigns", []):
            campaign_id = str(campaign["campaign_id"])
            for slot in campaign.get("slots", []):
                doc = reconcile_slot(slot, campaign_id, valid_by_slot, errors_by_slot, eval_dt)
                doc_id = f"{campaign_id}::{doc['execution_slot_id']}"
                session.put(f"{base}/{PLAN_STATUS_INDEX}/_doc/{doc_id}", json=doc, timeout=10.0).raise_for_status()

                summary[doc["receipt_status"]] += 1
                if doc["suite_completeness"] == "PARTIAL":
                    summary["PARTIAL"] += 1
                if doc["report_validity"] == "INVALID":
                    summary["INVALID"] += 1
                if doc["is_late"]:
                    summary["LATE"] += 1

    requests.post(f"{base}/{PLAN_STATUS_INDEX}/_refresh", timeout=5.0)
    summary["error_trends"] = _compute_error_trends(es_url)
    return summary

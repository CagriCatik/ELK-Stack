"""Unit tests for the reproducible <report> XML-v1 generator and XSD schema."""

from __future__ import annotations

import os
from datetime import datetime, timezone
from pathlib import Path
from xml.etree import ElementTree as ET

from lxml import etree

from xml_insight_lab.generator import generate_campaign_dataset, generate_fixtures
from xml_insight_lab.models import REGRESSION_SOFTWARE_VERSION, REGRESSION_TESTCASE_NAME, UNSTABLE_INIT_BENCH


def _ws() -> Path:
    return Path(os.environ.get("WORKSPACE_DIR", Path(__file__).resolve().parents[2]))


def _load_xsd() -> etree.XMLSchema:
    return etree.XMLSchema(etree.parse(str(_ws() / "schemas" / "execution-report-v1.xsd")))


def test_sample_report_validates_against_xsd() -> None:
    schema = _load_xsd()
    schema.assertValid(etree.parse(str(_ws() / "examples" / "sample-report-v1.xml")))


def test_reproducible_campaign_generation(tmp_path: Path) -> None:
    anchor = datetime(2026, 11, 17, 0, 0, 0, tzinfo=timezone.utc)
    res_a = generate_campaign_dataset(3, 42, tmp_path / "a_xml", tmp_path / "a_plan.yaml", anchor)
    res_b = generate_campaign_dataset(3, 42, tmp_path / "b_xml", tmp_path / "b_plan.yaml", anchor)

    assert (tmp_path / "a_plan.yaml").read_bytes() == (tmp_path / "b_plan.yaml").read_bytes()
    assert [p.name for p in res_a["files"]] == [p.name for p in res_b["files"]]
    for pa, pb in zip(res_a["files"], res_b["files"]):
        assert pa.read_bytes() == pb.read_bytes()


def test_generated_reports_validate_against_xsd(tmp_path: Path) -> None:
    schema = _load_xsd()
    anchor = datetime(2026, 11, 17, 0, 0, 0, tzinfo=timezone.utc)
    res = generate_campaign_dataset(5, 42, tmp_path / "xml", tmp_path / "plan.yaml", anchor)
    assert len(res["files"]) == 39
    assert len(res["omitted_slots"]) == 1
    assert len(res["partial_slots"]) == 1
    assert len(res["late_slots"]) == 1
    for f in res["files"]:
        schema.assertValid(etree.parse(str(f)))


def test_synthetic_patterns_present(tmp_path: Path) -> None:
    anchor = datetime(2026, 11, 17, 0, 0, 0, tzinfo=timezone.utc)
    res = generate_campaign_dataset(5, 42, tmp_path / "xml", tmp_path / "plan.yaml", anchor)

    reg_fails = 0
    lab02_init_fails = 0
    retries_seen = 0

    for f in res["files"]:
        root = ET.fromstring(f.read_text(encoding="utf-8"))
        bench_id = root.attrib["bench"]
        sw_ver = None
        for g in root.findall("groups"):
            if g.attrib["name"] == "initialization":
                if g.attrib.get("result") in ("FAILED", "ERROR") and bench_id == UNSTABLE_INIT_BENCH:
                    lab02_init_fails += 1
                for p in g.findall(".//param"):
                    if p.attrib["name"] == "SoftwareVersion":
                        sw_ver = p.attrib["value"]
            elif g.attrib["name"] != "deInitialization":
                for tc in g.findall("testCase"):
                    if int(tc.attrib.get("attempt", "1")) > 1:
                        retries_seen += 1
                    if tc.attrib["name"] == REGRESSION_TESTCASE_NAME and sw_ver == REGRESSION_SOFTWARE_VERSION:
                        if tc.attrib.get("result") == "FAILED":
                            reg_fails += 1

    assert reg_fails >= 1
    assert lab02_init_fails >= 1
    assert retries_seen >= 1


def test_fixtures_separation(tmp_path: Path) -> None:
    schema = _load_xsd()
    fx = generate_fixtures(tmp_path)
    assert len(fx["valid"]) == 1
    assert len(fx["invalid"]) == 4
    for vf in fx["valid"]:
        schema.assertValid(etree.parse(str(vf)))


def test_all_error_scenarios_deterministically_generated(tmp_path: Path) -> None:
    anchor = datetime(2026, 11, 17, 0, 0, 0, tzinfo=timezone.utc)
    res = generate_campaign_dataset(5, 42, tmp_path / "xml", tmp_path / "plan.yaml", anchor)
    all_text = "\n".join(p.read_text(encoding="utf-8") for p in res["files"])

    # Guaranteed scenarios from section 5
    for marker in (
        "UI_TIMEOUT",
        "IMG_CAPTURE_FAILED",
        "SYN_INIT_5001",
        "SYN_DEINIT_6001",
        "SYN_CONN_DROPPED",
        "SYN_SYNC_CHECKSUM",
        "expected 200 got 503",
        "Cache warm-up exceeded",
        "Unexpected synthetic anomaly XYZ-999",
        "InteractionService did not respond before deadline.",
    ):
        assert marker in all_text, f"Missing guaranteed scenario marker: {marker}"

    # XML files must never contain pre-classified engine outputs
    for forbidden in ("error_mapping", "UNCLASSIFIED", "KNOWN_ISSUE", "RELEVANT"):
        assert forbidden not in all_text, f"XML must not contain pre-classified field '{forbidden}'"

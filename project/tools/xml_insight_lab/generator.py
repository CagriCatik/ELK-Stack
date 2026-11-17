"""Reproducible synthetic nightly campaign plan and <report> XML-v1 generator."""

from __future__ import annotations

import random
from datetime import datetime, timedelta, timezone
from pathlib import Path
from xml.dom import minidom
from xml.etree.ElementTree import Element, SubElement, tostring

import yaml

from .models import (
    PROJECT_NAME,
    REGRESSION_SOFTWARE_VERSION,
    REGRESSION_TESTCASE_NAME,
    SCHEMA_VERSION,
    SOFTWARE_VERSIONS,
    SUITES,
    TEST_BENCHES,
    UNSTABLE_INIT_BENCH,
)


def _fmt_local_naive(dt: datetime) -> str:
    return dt.strftime("%Y-%m-%dT%H:%M:%S")


def _pretty_xml(root: Element) -> str:
    raw = tostring(root, encoding="utf-8")
    return minidom.parseString(raw).toprettyxml(indent="  ", encoding="utf-8").decode("utf-8")


def default_anchor_date(anchor_str: str | None = None) -> datetime:
    if anchor_str:
        dt = datetime.fromisoformat(anchor_str.replace("Z", "+00:00")).astimezone(timezone.utc)
        return dt.replace(hour=0, minute=0, second=0, microsecond=0)
    now = datetime.now(timezone.utc)
    return now.replace(hour=0, minute=0, second=0, microsecond=0)


def _error_code_for_component(component: str) -> str:
    mapping = {
        "CaptureService": "IMG_CAPTURE_FAILED",
        "InteractionService": "UI_TIMEOUT",
        "Connectivity": "SYN_CONN_DROPPED",
        "StorageService": "SYN_SYNC_CHECKSUM",
        "Output_A": "UI_TIMEOUT",
        "Output_B": "IMG_CAPTURE_FAILED",
    }
    return mapping.get(component, "SYN_STEP_FAILED")


def _build_report_xml(
    rng: random.Random,
    run_id: str,
    campaign_id: str,
    slot_id: str,
    bench_id: str,
    software_version: str,
    run_start_local: datetime,
    suite_names: list[str],
    night_index: int,
    slot_num: int,
) -> str:
    root = Element(
        "report",
        {
            "schemaVersion": SCHEMA_VERSION,
            "synthetic": "true",
            "id": run_id,
            "campaignId": campaign_id,
            "executionSlotId": slot_id,
            "bench": bench_id,
            "project": PROJECT_NAME,
            "startTime": _fmt_local_naive(run_start_local),
            "endTime": _fmt_local_naive(run_start_local),
            "result": "PASSED",
        },
    )

    init_fails = bench_id == UNSTABLE_INIT_BENCH and ((night_index % 2 == 1 and slot_num == 2) or rng.random() < 0.25)
    init_attrs = {"name": "initialization"}
    if init_fails:
        init_attrs["result"] = "ERROR"
    init_el = SubElement(root, "groups", init_attrs)
    setup_el = SubElement(init_el, "group", {"name": "SystemSetup"})
    SubElement(setup_el, "param", {"name": "SoftwareVersion", "value": software_version})
    SubElement(setup_el, "param", {"name": "TargetRegion", "value": "eu-demo"})
    SubElement(setup_el, "msg", {"level": "info"}).text = f"Synthetic bench {bench_id} initialized."
    if init_fails:
        SubElement(setup_el, "msg", {"level": "error"}).text = f"SYN_INIT_5001: {bench_id} workspace lock failed."
    else:
        SubElement(setup_el, "msg").text = "Init check completed without explicit msg level."

    total_seconds = 10.0
    any_failed = False
    any_error = init_fails

    for s_idx, s_name in enumerate(suite_names, 1):
        suite_ver = "2.1.0" if night_index >= 2 else "2.0.0"
        suite_el = SubElement(
            root,
            "groups",
            {"name": s_name, "id": f"suite-{s_name.lower()}", "version": suite_ver},
        )
        for tc_def in SUITES[s_name]:
            if init_fails:
                tc_el = SubElement(
                    suite_el,
                    "testCase",
                    {
                        "id": tc_def["id"],
                        "executionId": f"exec-{s_idx}-{tc_def['id']}",
                        "attempt": "1",
                        "name": tc_def["name"],
                        "result": "SKIPPED",
                    },
                )
                st = SubElement(tc_el, "step", {"name": "Skipped_Step", "result": "SKIPPED"})
                SubElement(st, "msg").text = "Skipped due to initialization error."
                continue

            is_reg = software_version == REGRESSION_SOFTWARE_VERSION and tc_def["name"] == REGRESSION_TESTCASE_NAME
            bench_hotspot = bench_id == "lab-04" and s_name == "Connectivity"
            creep = 1.0 + (0.25 * night_index) if s_name == "Settings" else 1.0

            fail_prob = 0.72 if is_reg else (0.55 if bench_hotspot else 0.14)
            tc_fail = rng.random() < fail_prob
            do_retry = tc_fail and not is_reg and rng.random() < 0.55
            attempts = [1, 2] if do_retry else [1]

            for attempt in attempts:
                res = "FAILED" if (tc_fail and attempt == 1) else "PASSED"
                if res == "FAILED":
                    any_failed = True
                dur_sec = round(rng.uniform(4.0, 20.0) * creep * (2.3 if is_reg else 1.0), 2)
                total_seconds += dur_sec

                tc_attrs = {
                    "id": tc_def["id"],
                    "executionId": f"exec-{s_idx}-{tc_def['id']}",
                    "attempt": str(attempt),
                    "name": tc_def["name"],
                    "result": res,
                }
                if not (s_name == "Settings" and attempt == 1 and slot_num == 1 and night_index == 0):
                    tc_attrs["duration"] = str(dur_sec)

                tc_el = SubElement(suite_el, "testCase", tc_attrs)
                if tc_def["name"] == "TC_WORKSPACE_Signal":
                    st1 = SubElement(tc_el, "step", {"name": "Emit_Signal", "result": "PASSED"})
                    SubElement(st1, "msg", {"level": "info"}).text = "First Emit_Signal sent."
                    st2 = SubElement(tc_el, "step", {"name": "Emit_Signal", "result": res})
                    if res == "FAILED":
                        SubElement(st2, "msg", {"level": "error"}).text = "UI_TIMEOUT waiting for Output_A."
                        errs = SubElement(tc_el, "errors")
                        SubElement(errs, "msg").text = "UI_TIMEOUT in InteractionService."
                    else:
                        SubElement(st2, "msg", {"level": "info"}).text = "Second Emit_Signal acknowledged."
                else:
                    st = SubElement(tc_el, "step", {"name": f"Run_{tc_def['component']}", "result": res})
                    if res == "FAILED":
                        code = _error_code_for_component(tc_def["component"])
                        SubElement(st, "msg", {"level": "error"}).text = f"{code} on {tc_def['component']}."
                        errs = SubElement(tc_el, "errors")
                        SubElement(errs, "msg").text = f"{code}: synthetic failure detail on {bench_id}."
                    else:
                        SubElement(st, "msg", {"level": "info"}).text = f"{tc_def['component']} step ok."

    deinit_fail = not init_fails and bench_id == "lab-03" and night_index >= 3 and slot_num == 1
    if deinit_fail:
        any_error = True
    deinit_el = SubElement(root, "groups", {"name": "deInitialization", "result": "ERROR" if deinit_fail else "PASSED"})
    cl_el = SubElement(deinit_el, "group", {"name": "Cleanup"})
    SubElement(cl_el, "msg", {"level": "error" if deinit_fail else "info"}).text = (
        "SYN_DEINIT_6001: Cleanup lock error." if deinit_fail else "Resources released cleanly."
    )
    dt_tc = SubElement(
        deinit_el,
        "testCase",
        {"id": "TC_DEINIT_CLEANUP", "executionId": "exec-deinit-1", "attempt": "1", "name": "TC_DEINIT_CLEANUP", "result": "PASSED", "duration": "3.5"},
    )
    dt_st = SubElement(dt_tc, "step", {"name": "Release_Resources", "result": "PASSED"})
    SubElement(dt_st, "msg", {"level": "info"}).text = "Deinit testCase passed."

    end_local = run_start_local + timedelta(seconds=int(total_seconds))
    root.set("endTime", _fmt_local_naive(end_local))
    root.set("result", "ERROR" if any_error else ("FAILED" if any_failed else "PASSED"))
    return _pretty_xml(root)


def generate_campaign_dataset(
    nights: int,
    seed: int,
    output_dir: Path,
    plan_path: Path,
    anchor_date: datetime,
) -> dict[str, object]:
    rng = random.Random(seed)
    output_dir.mkdir(parents=True, exist_ok=True)
    plan_path.parent.mkdir(parents=True, exist_ok=True)

    campaigns_plan: list[dict[str, object]] = []
    written_files: list[Path] = []
    omitted_slots: list[str] = []
    partial_slots: list[str] = []
    late_slots: list[str] = []

    first_night = anchor_date - timedelta(days=nights - 1)
    all_suites = list(SUITES.keys())

    for n_idx in range(nights):
        night_dt = first_night + timedelta(days=n_idx)
        campaign_id = f"nightly-{night_dt.strftime('%Y%m%d')}"
        night_sw = SOFTWARE_VERSIONS[min((n_idx * len(SOFTWARE_VERSIONS)) // max(1, nights), len(SOFTWARE_VERSIONS) - 1)]
        slots: list[dict[str, object]] = []

        for b_idx, bench_id in enumerate(TEST_BENCHES):
            # 2 scheduled runs per bench per night with different suite subsets
            for slot_num in (1, 2):
                expected_suites = all_suites if slot_num == 1 else ["Workspace", "Content", "Connectivity"]
                expected_start_utc = night_dt + timedelta(hours=b_idx, minutes=30 * (slot_num - 1))
                deadline_utc = expected_start_utc + timedelta(minutes=25)
                slot_id = f"slot-{campaign_id}-{bench_id}-{slot_num:02d}"

                slots.append(
                    {
                        "execution_slot_id": slot_id,
                        "test_bench": {"id": bench_id},
                        "project": PROJECT_NAME,
                        "expected_suites": expected_suites,
                        "expected_started_at": expected_start_utc.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
                        "deadline_at": deadline_utc.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
                    }
                )

                if n_idx == nights - 1 and bench_id == "lab-03" and slot_num == 2:
                    omitted_slots.append(slot_id)
                    continue

                suites_to_emit = list(expected_suites)
                if n_idx == nights - 1 and bench_id == "lab-02" and slot_num == 1:
                    suites_to_emit = [s for s in expected_suites if s != "Settings"]
                    partial_slots.append(slot_id)

                local_start = expected_start_utc + timedelta(hours=1, minutes=4)
                if n_idx == nights - 1 and bench_id == "lab-01" and slot_num == 1:
                    local_start = deadline_utc + timedelta(hours=1, minutes=10)
                    late_slots.append(slot_id)

                run_id = f"run-{bench_id}-{night_dt.strftime('%Y%m%d')}-{slot_num:03d}"
                xml_str = _build_report_xml(
                    rng=rng,
                    run_id=run_id,
                    campaign_id=campaign_id,
                    slot_id=slot_id,
                    bench_id=bench_id,
                    software_version=night_sw,
                    run_start_local=local_start,
                    suite_names=suites_to_emit,
                    night_index=n_idx,
                    slot_num=slot_num,
                )
                p = output_dir / f"{run_id}.xml"
                p.write_text(xml_str, encoding="utf-8")
                written_files.append(p)

        campaigns_plan.append({"campaign_id": campaign_id, "slots": slots})

    plan_doc = {"synthetic": True, "schema_version": SCHEMA_VERSION, "seed": seed, "campaigns": campaigns_plan}
    plan_path.write_text(yaml.safe_dump(plan_doc, sort_keys=False), encoding="utf-8")
    return {
        "files": written_files,
        "plan_path": plan_path,
        "omitted_slots": omitted_slots,
        "partial_slots": partial_slots,
        "late_slots": late_slots,
    }


def generate_fixtures(base_dir: Path) -> dict[str, list[Path]]:
    valid_dir = base_dir / "valid"
    invalid_dir = base_dir / "invalid"
    valid_dir.mkdir(parents=True, exist_ok=True)
    invalid_dir.mkdir(parents=True, exist_ok=True)

    valid_files: dict[str, str] = {
        "01-extra-group-no-tcs.xml": """<?xml version="1.0" encoding="UTF-8"?>
<report bench="lab-01" project="SampleProject" startTime="2026-11-17T02:00:00" endTime="2026-11-17T02:01:00" result="PASSED">
  <groups name="initialization">
    <group name="Setup"><msg level="info">OK</msg></group>
  </groups>
  <groups name="CustomDiagnostics">
    <msg>Diagnostic group without testCase elements.</msg>
  </groups>
  <groups name="Workspace">
    <testCase name="TC_WORKSPACE_SINGLE" result="PASSED" duration="5.0">
      <step name="Check" result="PASSED"><msg level="info">Single step ok.</msg></step>
    </testCase>
  </groups>
  <groups name="deInitialization" result="PASSED"/>
</report>
""",
    }

    invalid_files: dict[str, str] = {
        "01-malformed-xml.xml": '<report bench="lab-01" project="SampleProject"><groups name="broken"',
        "02-nonexistent-dst-time.xml": """<?xml version="1.0" encoding="UTF-8"?>
<report bench="lab-01" project="SampleProject" startTime="2026-03-29T02:30:00" endTime="2026-03-29T03:30:00" result="PASSED">
  <groups name="initialization"/>
</report>
""",
        "03-end-before-start.xml": """<?xml version="1.0" encoding="UTF-8"?>
<report bench="lab-01" project="SampleProject" startTime="2026-11-17T05:00:00" endTime="2026-11-17T04:00:00" result="PASSED">
  <groups name="initialization"/>
</report>
""",
        "04-dtd-rejected.xml": """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE report [<!ENTITY test "forbidden">]>
<report bench="lab-01" project="SampleProject" startTime="2026-11-17T02:00:00" endTime="2026-11-17T02:01:00" result="PASSED">
  <groups name="initialization"/>
</report>
""",
    }

    written_valid = []
    for name, content in valid_files.items():
        p = valid_dir / name
        p.write_text(content, encoding="utf-8")
        written_valid.append(p)

    written_invalid = []
    for name, content in invalid_files.items():
        p = invalid_dir / name
        p.write_text(content, encoding="utf-8")
        written_invalid.append(p)

    return {"valid": written_valid, "invalid": written_invalid}

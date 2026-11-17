"""Unit tests for campaign plan reconciliation (report + expected suites)."""

from __future__ import annotations

from datetime import datetime, timezone

from xml_insight_lab.reconciler import reconcile_slot


def _sample_slot() -> dict:
    return {
        "execution_slot_id": "slot-nightly-20261117-lab-01-01",
        "test_bench": {"id": "lab-01"},
        "project": "SampleProject",
        "expected_suites": ["Workspace", "Content", "Settings"],
        "expected_started_at": "2026-11-17T01:00:00.000Z",
        "deadline_at": "2026-11-17T01:30:00.000Z",
    }


def test_reconcile_pending_and_missing() -> None:
    slot = _sample_slot()
    pending = reconcile_slot(slot, "nightly-20261117", {}, {}, datetime(2026, 11, 17, 1, 15, tzinfo=timezone.utc))
    assert pending["receipt_status"] == "PENDING"
    assert pending["suite_completeness"] == "NONE"

    missing = reconcile_slot(slot, "nightly-20261117", {}, {}, datetime(2026, 11, 17, 2, 0, tzinfo=timezone.utc))
    assert missing["receipt_status"] == "MISSING"
    assert missing["missing_suites"] == ["Workspace", "Content", "Settings"]


def test_reconcile_complete_vs_partial_suites() -> None:
    slot = _sample_slot()
    sid = slot["execution_slot_id"]
    eval_at = datetime(2026, 11, 17, 3, 0, tzinfo=timezone.utc)

    partial_run = {
        "run": {"id": "run-partial"},
        "normalized_result": "PASSED",
        "started_at": "2026-11-17T01:05:00.000Z",
        "suite_names": ["Workspace", "Content"],
    }
    res_p = reconcile_slot(slot, "nightly-20261117", {sid: partial_run}, {}, eval_at)
    assert res_p["receipt_status"] == "RECEIVED"
    assert res_p["suite_completeness"] == "PARTIAL"
    assert res_p["missing_suites"] == ["Settings"]

    full_run = {**partial_run, "suite_names": ["Workspace", "Content", "Settings"]}
    res_f = reconcile_slot(slot, "nightly-20261117", {sid: full_run}, {}, eval_at)
    assert res_f["suite_completeness"] == "COMPLETE"
    assert res_f["missing_suites"] == []


def test_reconcile_invalid_report_never_treated_as_passed() -> None:
    slot = _sample_slot()
    sid = slot["execution_slot_id"]
    eval_at = datetime(2026, 11, 17, 3, 0, tzinfo=timezone.utc)
    err = {"run": {"id": "run-bad"}, "ingested_at": "2026-11-17T01:10:00.000Z"}
    res = reconcile_slot(slot, "nightly-20261117", {}, {sid: err}, eval_at)
    assert res["receipt_status"] == "RECEIVED"
    assert res["report_validity"] == "INVALID"
    assert "run_result" not in res

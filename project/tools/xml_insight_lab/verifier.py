"""Elasticsearch indexing verification across all 7 index families."""

from __future__ import annotations

import time
import requests

from .models import (
    ERRORS_INDEX,
    MESSAGES_INDEX,
    PLAN_STATUS_INDEX,
    RUNS_INDEX,
    STEPS_INDEX,
    SUITES_INDEX,
    TESTCASES_INDEX,
)


def get_index_count(es_url: str, index_name: str, timeout: float = 5.0) -> int:
    resp = requests.get(f"{es_url.rstrip('/')}/{index_name}/_count", timeout=timeout)
    if resp.status_code == 404:
        return 0
    resp.raise_for_status()
    return int(resp.json().get("count", 0))


def refresh_indices(
    es_url: str,
    indices: tuple[str, ...] = (
        RUNS_INDEX,
        SUITES_INDEX,
        TESTCASES_INDEX,
        STEPS_INDEX,
        MESSAGES_INDEX,
        ERRORS_INDEX,
        PLAN_STATUS_INDEX,
    ),
) -> None:
    for idx in indices:
        resp = requests.post(f"{es_url.rstrip('/')}/{idx}/_refresh", timeout=5.0)
        if resp.status_code not in (200, 404):
            resp.raise_for_status()


def verify_counts(
    es_url: str,
    min_runs: int = 1,
    min_suites: int = 1,
    min_testcases: int = 1,
    min_steps: int = 1,
    min_messages: int = 1,
    min_errors: int = 0,
    min_plan_slots: int = 0,
    timeout_seconds: float = 60.0,
    poll_interval: float = 2.0,
) -> dict[str, int]:
    deadline = time.monotonic() + timeout_seconds
    while True:
        refresh_indices(es_url)
        counts = {
            RUNS_INDEX: get_index_count(es_url, RUNS_INDEX),
            SUITES_INDEX: get_index_count(es_url, SUITES_INDEX),
            TESTCASES_INDEX: get_index_count(es_url, TESTCASES_INDEX),
            STEPS_INDEX: get_index_count(es_url, STEPS_INDEX),
            MESSAGES_INDEX: get_index_count(es_url, MESSAGES_INDEX),
            ERRORS_INDEX: get_index_count(es_url, ERRORS_INDEX),
            PLAN_STATUS_INDEX: get_index_count(es_url, PLAN_STATUS_INDEX),
        }
        if (
            counts[RUNS_INDEX] >= min_runs
            and counts[SUITES_INDEX] >= min_suites
            and counts[TESTCASES_INDEX] >= min_testcases
            and counts[STEPS_INDEX] >= min_steps
            and counts[MESSAGES_INDEX] >= min_messages
            and counts[ERRORS_INDEX] >= min_errors
            and counts[PLAN_STATUS_INDEX] >= min_plan_slots
        ):
            return counts

        if time.monotonic() >= deadline:
            raise TimeoutError(f"Timed out after {timeout_seconds}s waiting for ES counts; got {counts}")
        time.sleep(poll_interval)

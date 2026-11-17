"""Shared constants and domain definitions for XML Insight Lab."""

from __future__ import annotations

SCHEMA_VERSION = "1.0"
PROJECT_NAME = "SampleProject"

TEST_BENCHES = ("lab-01", "lab-02", "lab-03", "lab-04")

SUITES = {
    "Workspace": (
        {"id": "TC_WORKSPACE_001", "name": "TC_WORKSPACE_Open", "component": "Output_A"},
        {"id": "TC_WORKSPACE_002", "name": "TC_WORKSPACE_Signal", "component": "InteractionService"},
    ),
    "Content": (
        {"id": "TC_CONTENT_001", "name": "TC_CONTENT_Capture", "component": "CaptureService"},
        {"id": "TC_CONTENT_002", "name": "TC_CONTENT_Stream", "component": "Output_B"},
    ),
    "Settings": (
        {"id": "TC_SETTINGS_001", "name": "TC_SETTINGS_Profile", "component": "InteractionService"},
        {"id": "TC_SETTINGS_002", "name": "TC_SETTINGS_Persist", "component": "StorageService"},
    ),
    "Connectivity": (
        {"id": "TC_CONN_001", "name": "TC_CONN_Handshake", "component": "Connectivity"},
        {"id": "TC_CONN_002", "name": "TC_CONN_Keepalive", "component": "Connectivity"},
    ),
    "StorageSync": (
        {"id": "TC_SYNC_001", "name": "TC_SYNC_Snapshot", "component": "StorageService"},
        {"id": "TC_SYNC_002", "name": "TC_SYNC_Checksum", "component": "StorageService"},
    ),
}

SOFTWARE_VERSIONS = ("1.3.0", "1.4.0", "1.5.0-rc1")
REGRESSION_SOFTWARE_VERSION = "1.5.0-rc1"
REGRESSION_TESTCASE_NAME = "TC_CONTENT_Capture"
UNSTABLE_INIT_BENCH = "lab-02"

RUNS_INDEX = "xml-insight-runs-v1"
SUITES_INDEX = "xml-insight-suites-v1"
TESTCASES_INDEX = "xml-insight-testcases-v1"
STEPS_INDEX = "xml-insight-steps-v1"
MESSAGES_INDEX = "xml-insight-messages-v1"
ERRORS_INDEX = "xml-insight-errors-v1"
PLAN_STATUS_INDEX = "xml-insight-plan-status-v1"

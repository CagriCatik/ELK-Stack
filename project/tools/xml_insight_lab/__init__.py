"""Shared constants and schema definitions for XML Insight Lab."""

from __future__ import annotations

SCHEMA_VERSION = "1.0"
GENERATOR_ID = "xml-insight-lab-v1"

ENVIRONMENTS = ("local", "staging-demo", "ci-sandbox")
SOFTWARE_VERSIONS = ("v1.4.0", "v1.5.0", "v1.6.0-rc1")
REGRESSION_VERSION = "v1.6.0-rc1"
REGRESSION_COMPONENT = "storage-gamma"

COMPONENTS = (
    "scheduler-beta",
    "worker-alpha",
    "parser-delta",
    "storage-gamma",
    "notifier-epsilon",
)

OPERATIONS_BY_COMPONENT = {
    "scheduler-beta": ("acquire_lease", "dispatch_job"),
    "worker-alpha": ("transform_payload", "enrich_metadata"),
    "parser-delta": ("validate_structure", "extract_tokens"),
    "storage-gamma": ("persist_snapshot", "flush_segment"),
    "notifier-epsilon": ("emit_summary", "update_registry"),
}

OVERALL_STATUSES = ("PASSED", "FAILED", "TIMEOUT", "ABORTED")
STEP_STATUSES = ("OK", "SLOW", "TIMEOUT", "ERROR", "SKIPPED")

RUNS_INDEX = "xml-insight-runs-v1"
STEPS_INDEX = "xml-insight-steps-v1"
ERRORS_INDEX = "xml-insight-errors-v1"

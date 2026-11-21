"""Validation tests for the central config/error_mapping.yaml file."""

from __future__ import annotations

import os
import re
from pathlib import Path

import yaml


def _config_path() -> Path:
    ws = Path(os.environ.get("WORKSPACE_DIR", Path(__file__).resolve().parents[2]))
    return ws / "config" / "error_mapping.yaml"


def test_error_mapping_yaml_is_valid() -> None:
    cfg = yaml.safe_load(_config_path().read_text(encoding="utf-8"))
    assert cfg["version"] == "1.0"
    assert cfg["defaults"]["disposition"] == "UNCLASSIFIED"
    assert cfg["defaults"]["category"] == "UNKNOWN"

    seen_ids: set[str] = set()
    valid_types = {"exact", "contains", "regex", "error_code"}
    valid_disp = {"RELEVANT", "KNOWN_ISSUE", "IGNORED", "UNCLASSIFIED"}
    valid_sev = {"CRITICAL", "HIGH", "MEDIUM", "LOW", "INFO"}

    for rule in cfg["rules"]:
        rid = rule["id"]
        assert rid not in seen_ids, f"Duplicate rule id: {rid}"
        seen_ids.add(rid)
        assert isinstance(rule["priority"], int)
        mtype = rule["match"]["type"]
        assert mtype in valid_types
        if mtype == "regex":
            for pat in rule["match"]["patterns"]:
                re.compile(pat)
        cls = rule["classification"]
        assert cls["disposition"] in valid_disp
        assert cls["severity"] in valid_sev

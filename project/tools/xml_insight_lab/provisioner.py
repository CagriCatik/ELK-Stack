"""Provisioning helpers for Elasticsearch index templates and Kibana saved objects."""

from __future__ import annotations

import json
from pathlib import Path
import requests


def install_es_templates(es_url: str, templates_dir: Path) -> list[str]:
    """Install all `*.json` composable index templates into Elasticsearch."""
    installed: list[str] = []
    base = es_url.rstrip("/")
    for path in sorted(templates_dir.glob("*.json")):
        template_name = path.stem
        payload = json.loads(path.read_text(encoding="utf-8"))
        resp = requests.put(
            f"{base}/_index_template/{template_name}",
            json=payload,
            timeout=10.0,
        )
        resp.raise_for_status()
        installed.append(template_name)
    return installed


def import_kibana_saved_objects(kibana_url: str, ndjson_path: Path) -> dict[str, object]:
    """Import Kibana Data Views and Dashboard via official Saved Objects Import API."""
    base = kibana_url.rstrip("/")
    with ndjson_path.open("rb") as fh:
        resp = requests.post(
            f"{base}/api/saved_objects/_import?overwrite=true",
            headers={"kbn-xsrf": "true"},
            files={"file": (ndjson_path.name, fh, "application/ndjson")},
            timeout=20.0,
        )
    resp.raise_for_status()
    result = resp.json()
    if not result.get("success"):
        raise RuntimeError(f"Kibana saved objects import failed: {result}")
    return result

"""XML envelope uploader for Logstash HTTP input."""

from __future__ import annotations

import hashlib
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

import requests


@dataclass
class UploadSummary:
    """Summary of HTTP envelope submissions to Logstash."""

    total_files: int = 0
    accepted: int = 0
    failed: int = 0
    failed_files: list[tuple[str, str]] = field(default_factory=list)


def discover_xml_files(target: Path, recursive: bool = False) -> list[Path]:
    """Discover `.xml` files from a single file or directory."""
    if not target.exists():
        raise FileNotFoundError(f"Path does not exist: {target}")
    if target.is_file():
        return [target]
    pattern = "**/*.xml" if recursive else "*.xml"
    return sorted(p for p in target.glob(pattern) if p.is_file())


def build_envelope(file_path: Path) -> dict[str, object]:
    """Read an XML file and wrap it in a JSON envelope without pre-parsing."""
    raw_bytes = file_path.read_bytes()
    raw_xml = raw_bytes.decode("utf-8", errors="replace")
    sha256 = hashlib.sha256(raw_bytes).hexdigest()
    return {
        "raw_xml": raw_xml,
        "source_file": file_path.name,  # Logical filename only; never leak local paths
        "file_sha256": sha256,
        "synthetic_origin": True,
        "ingested_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z",
    }


def post_envelope_with_retry(
    session: requests.Session,
    logstash_url: str,
    envelope: dict[str, object],
    max_retries: int = 3,
    backoff_base: float = 0.5,
    timeout: float = 10.0,
) -> None:
    """POST a single JSON envelope with bounded retries on transient errors."""
    last_exc: Exception | None = None
    for attempt in range(max_retries + 1):
        try:
            resp = session.post(logstash_url, json=envelope, timeout=timeout)
            if 200 <= resp.status_code < 300:
                return
            if resp.status_code < 500 and resp.status_code != 429:
                raise RuntimeError(f"HTTP {resp.status_code}: {resp.text[:200]}")
            last_exc = RuntimeError(f"HTTP {resp.status_code}: {resp.text[:200]}")
        except (requests.ConnectionError, requests.Timeout) as exc:
            last_exc = exc

        if attempt < max_retries:
            time.sleep(backoff_base * (2**attempt))

    raise RuntimeError(f"Failed after {max_retries + 1} attempts: {last_exc}")


def upload_files(
    files: Iterable[Path],
    logstash_url: str,
    max_retries: int = 3,
    backoff_base: float = 0.5,
    timeout: float = 10.0,
) -> UploadSummary:
    """Upload a collection of XML files as JSON envelopes to Logstash."""
    file_list = list(files)
    summary = UploadSummary(total_files=len(file_list))
    with requests.Session() as session:
        for file_path in file_list:
            try:
                envelope = build_envelope(file_path)
                post_envelope_with_retry(
                    session=session,
                    logstash_url=logstash_url,
                    envelope=envelope,
                    max_retries=max_retries,
                    backoff_base=backoff_base,
                    timeout=timeout,
                )
                summary.accepted += 1
            except Exception as exc:  # noqa: BLE001
                summary.failed += 1
                summary.failed_files.append((file_path.name, str(exc)))
    return summary

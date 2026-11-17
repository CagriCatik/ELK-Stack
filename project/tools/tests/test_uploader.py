"""Unit tests for the XML envelope uploader."""

from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock

import pytest
import requests

from xml_insight_lab.uploader import (
    build_envelope,
    discover_xml_files,
    post_envelope_with_retry,
)


def test_build_envelope_strips_local_paths(tmp_path: Path) -> None:
    nested = tmp_path / "secret_user_dir" / "nested"
    nested.mkdir(parents=True)
    xml_file = nested / "demo-report.xml"
    xml_file.write_text("<executionReport/>", encoding="utf-8")

    env = build_envelope(xml_file)
    assert env["raw_xml"] == "<executionReport/>"
    assert env["source_file"] == "demo-report.xml"
    assert "secret_user_dir" not in str(env["source_file"])
    assert env["synthetic_origin"] is True
    assert len(str(env["file_sha256"])) == 64


def test_discover_xml_files_recursive(tmp_path: Path) -> None:
    (tmp_path / "a.xml").write_text("<a/>", encoding="utf-8")
    sub = tmp_path / "sub"
    sub.mkdir()
    (sub / "b.xml").write_text("<b/>", encoding="utf-8")
    (sub / "ignore.txt").write_text("x", encoding="utf-8")

    flat = discover_xml_files(tmp_path, recursive=False)
    rec = discover_xml_files(tmp_path, recursive=True)

    assert [p.name for p in flat] == ["a.xml"]
    assert [p.name for p in rec] == ["a.xml", "b.xml"]


def test_post_envelope_retries_transient_failure() -> None:
    session = MagicMock(spec=requests.Session)
    ok_resp = MagicMock()
    ok_resp.status_code = 200
    session.post.side_effect = [requests.ConnectionError("transient"), ok_resp]

    post_envelope_with_retry(
        session=session,
        logstash_url="http://localhost:8080",
        envelope={"raw_xml": "<x/>"},
        max_retries=2,
        backoff_base=0.01,
    )
    assert session.post.call_count == 2


def test_post_envelope_fails_after_max_retries() -> None:
    session = MagicMock(spec=requests.Session)
    session.post.side_effect = requests.Timeout("timed out")

    with pytest.raises(RuntimeError, match="Failed after 2 attempts"):
        post_envelope_with_retry(
            session=session,
            logstash_url="http://localhost:8080",
            envelope={"raw_xml": "<x/>"},
            max_retries=1,
            backoff_base=0.01,
        )

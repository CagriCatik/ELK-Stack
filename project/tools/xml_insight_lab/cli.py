"""Command-line interface for XML Insight Lab."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from .generator import default_anchor_date, generate_campaign_dataset, generate_fixtures
from .provisioner import import_kibana_saved_objects, install_es_templates
from .reconciler import parse_utc, reconcile_plan
from .uploader import discover_xml_files, upload_files
from .verifier import verify_counts


def _default_workspace() -> Path:
    return Path(os.environ.get("WORKSPACE_DIR", "/workspace"))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="xml-insight", description="XML Insight Lab CLI")
    sub = parser.add_subparsers(dest="command", required=True)

    gen_p = sub.add_parser("generate", help="Generate reproducible multi-night campaign plan & XML reports")
    gen_p.add_argument("--nights", type=int, default=3)
    gen_p.add_argument("--seed", type=int, default=42)
    gen_p.add_argument("--anchor-date", type=str, default=None)
    gen_p.add_argument("--output", type=Path, default=Path("/data/generated"))
    gen_p.add_argument("--plan-output", type=Path, default=Path("/data/plan/campaign-plan.yaml"))
    gen_p.add_argument("--with-fixtures", type=Path, default=None)

    up_p = sub.add_parser("upload", help="Upload XML files as JSON envelopes to Logstash")
    up_p.add_argument("path", type=Path)
    up_p.add_argument("--recursive", action="store_true")
    up_p.add_argument("--logstash-url", type=str, default=os.environ.get("LOGSTASH_URL", "http://logstash:8080"))
    up_p.add_argument("--retries", type=int, default=3)

    rec_p = sub.add_parser("reconcile", help="Reconcile campaign plan and compute error trends")
    rec_p.add_argument("--plan", type=Path, default=Path("/data/plan/campaign-plan.yaml"))
    rec_p.add_argument("--evaluated-at", type=str, default=None)
    rec_p.add_argument("--es-url", type=str, default=os.environ.get("ES_URL", "http://elasticsearch:9200"))

    ver_p = sub.add_parser("verify", help="Poll Elasticsearch and verify indexed document counts")
    ver_p.add_argument("--es-url", type=str, default=os.environ.get("ES_URL", "http://elasticsearch:9200"))
    ver_p.add_argument("--min-runs", type=int, default=1)
    ver_p.add_argument("--min-suites", type=int, default=1)
    ver_p.add_argument("--min-testcases", type=int, default=1)
    ver_p.add_argument("--min-steps", type=int, default=1)
    ver_p.add_argument("--min-messages", type=int, default=1)
    ver_p.add_argument("--min-errors", type=int, default=0)
    ver_p.add_argument("--min-plan-slots", type=int, default=0)
    ver_p.add_argument("--timeout", type=float, default=60.0)

    pes_p = sub.add_parser("provision-es", help="Install Elasticsearch index templates")
    pes_p.add_argument("--es-url", type=str, default=os.environ.get("ES_URL", "http://elasticsearch:9200"))
    pes_p.add_argument("--templates-dir", type=Path, default=_default_workspace() / "elasticsearch" / "templates")

    pkb_p = sub.add_parser("provision-kibana", help="Import Kibana Data Views and Dashboards")
    pkb_p.add_argument("--kibana-url", type=str, default=os.environ.get("KIBANA_URL", "http://kibana:5601"))
    pkb_p.add_argument("--ndjson", type=Path, default=_default_workspace() / "kibana" / "provisioning" / "xml-insight-dashboard.ndjson")

    args = parser.parse_args(argv)

    if args.command == "generate":
        anchor = default_anchor_date(args.anchor_date)
        res = generate_campaign_dataset(args.nights, args.seed, args.output, args.plan_output, anchor)
        print(
            f"Generated {len(res['files'])} XML reports in {args.output} "
            f"and campaign plan at {res['plan_path']} "
            f"(omitted={len(res['omitted_slots'])}, partial={len(res['partial_slots'])}, late={len(res['late_slots'])})"
        )
        if args.with_fixtures:
            fx = generate_fixtures(args.with_fixtures)
            print(f"Generated {len(fx['valid'])} valid and {len(fx['invalid'])} invalid fixtures in {args.with_fixtures}")
        return 0

    if args.command == "upload":
        files = discover_xml_files(args.path, recursive=args.recursive)
        if not files:
            print(f"No XML files found at {args.path}", file=sys.stderr)
            return 1
        summary = upload_files(files, args.logstash_url, max_retries=args.retries)
        print(f"HTTP transfer summary: total={summary.total_files} accepted={summary.accepted} failed={summary.failed}")
        for fname, err in summary.failed_files:
            print(f"  FAILED {fname}: {err}", file=sys.stderr)
        return 0 if summary.failed == 0 else 2

    if args.command == "reconcile":
        eval_dt = parse_utc(args.evaluated_at) if args.evaluated_at else None
        res = reconcile_plan(args.plan, args.es_url, evaluated_at=eval_dt)
        print(f"Reconciled campaign plan: {res}")
        return 0

    if args.command == "verify":
        counts = verify_counts(
            es_url=args.es_url,
            min_runs=args.min_runs,
            min_suites=args.min_suites,
            min_testcases=args.min_testcases,
            min_steps=args.min_steps,
            min_messages=args.min_messages,
            min_errors=args.min_errors,
            min_plan_slots=args.min_plan_slots,
            timeout_seconds=args.timeout,
        )
        print(f"Verified Elasticsearch counts: {counts}")
        return 0

    if args.command == "provision-es":
        installed = install_es_templates(args.es_url, args.templates_dir)
        print(f"Installed Elasticsearch index templates: {', '.join(installed)}")
        return 0

    if args.command == "provision-kibana":
        res = import_kibana_saved_objects(args.kibana_url, args.ndjson)
        print(f"Imported Kibana saved objects: successCount={res.get('successCount')}")
        return 0

    return 1


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_DIR}"

echo "=== XML Insight Lab: <report> XML-v1 Demo Launcher ==="

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or not in PATH." >&2
  exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "Error: docker compose v2 is required." >&2
  exit 1
fi

echo "[1/9] Validating Compose configuration and building Python tools container..."
docker compose config -q
docker compose --profile tools build tools

echo "[2/9] Starting Elasticsearch, Logstash, and Kibana (waiting for healthchecks)..."
docker compose up -d --wait elasticsearch logstash kibana

echo "[3/9] Installing explicit Elasticsearch index templates (7 index families)..."
docker compose run --rm tools provision-es

echo "[4/9] Generating 5-night synthetic campaign plan, <report> XMLs (seed=42), and fixtures..."
rm -rf "${PROJECT_DIR}/data/generated" "${PROJECT_DIR}/data/fixtures" "${PROJECT_DIR}/data/plan"
docker compose run --rm tools generate \
  --nights 5 \
  --seed 42 \
  --output /data/generated \
  --plan-output /data/plan/campaign-plan.yaml \
  --with-fixtures /data/fixtures

echo "[5/9] Uploading canonical example, generated reports, and valid/invalid fixtures..."
docker compose run --rm tools upload /workspace/examples/sample-report-v1.xml
docker compose run --rm tools upload /data/generated
docker compose run --rm tools upload /data/fixtures/valid
docker compose run --rm tools upload /data/fixtures/invalid

echo "[6/9] Waiting for Elasticsearch indexing across runs, suites, testcases, steps, messages, and errors..."
docker compose run --rm tools verify \
  --min-runs 10 --min-suites 25 --min-testcases 45 --min-steps 50 --min-messages 40 --min-errors 4 --timeout 90

echo "[7/9] Reconciling campaign plan (reports + expected suites) and computing error trends..."
docker compose run --rm tools reconcile --plan /data/plan/campaign-plan.yaml

echo "[8/9] Provisioning Kibana Data Views and Dashboards..."
docker compose run --rm tools provision-kibana

echo "[9/9] Final verification..."
docker compose run --rm tools verify \
  --min-runs 10 --min-suites 25 --min-testcases 45 --min-steps 50 --min-messages 40 --min-errors 4 --min-plan-slots 9 --timeout 30

echo ""
echo "Demo ready!"
echo "  Elasticsearch     : http://127.0.0.1:${ES_HOST_PORT:-9200}"
echo "  Kibana UI         : http://127.0.0.1:${KIBANA_HOST_PORT:-5601}"
echo "  Nightly Overview  : http://127.0.0.1:${KIBANA_HOST_PORT:-5601}/app/dashboards#/view/xml-insight-nightly-overview"
echo "  Suite Overview    : http://127.0.0.1:${KIBANA_HOST_PORT:-5601}/app/dashboards#/view/xml-insight-suite-overview"
echo "  Run Details       : http://127.0.0.1:${KIBANA_HOST_PORT:-5601}/app/dashboards#/view/xml-insight-run-details"
echo "  Test Details      : http://127.0.0.1:${KIBANA_HOST_PORT:-5601}/app/dashboards#/view/xml-insight-test-details"

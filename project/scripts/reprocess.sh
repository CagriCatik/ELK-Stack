#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_DIR}"

echo "=== XML Insight Lab: Controlled Historical Reprocessing ==="
echo "[1/4] Restarting Logstash to load latest config/error_mapping.yaml..."
docker compose restart logstash
docker compose up -d --wait logstash

echo "[2/4] Re-uploading existing XML reports (deterministic IDs prevent duplicates)..."
if [[ -f "${PROJECT_DIR}/examples/sample-report-v1.xml" ]]; then
  docker compose run --rm tools upload /workspace/examples/sample-report-v1.xml
fi
if [[ -d "${PROJECT_DIR}/data/generated" ]]; then
  docker compose run --rm tools upload /data/generated
fi
if [[ -d "${PROJECT_DIR}/data/fixtures/valid" ]]; then
  docker compose run --rm tools upload /data/fixtures/valid
fi

echo "[3/4] Waiting for Elasticsearch indexing..."
docker compose run --rm tools verify --min-runs 1 --min-testcases 1 --min-steps 1 --timeout 60

if [[ -f "${PROJECT_DIR}/data/plan/campaign-plan.yaml" ]]; then
  echo "[4/4] Re-running campaign plan reconciliation..."
  docker compose run --rm tools reconcile --plan /data/plan/campaign-plan.yaml
fi

echo "Reprocessing complete."

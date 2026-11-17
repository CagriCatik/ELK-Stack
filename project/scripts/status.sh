#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_DIR}"

echo "=== Container Status ==="
docker compose ps

echo ""
echo "=== Elasticsearch Cluster Health ==="
curl -fsS "http://127.0.0.1:${ES_HOST_PORT:-9200}/_cluster/health?pretty" || echo "Elasticsearch unreachable"

echo ""
echo "=== Index Document Counts ==="
for idx in xml-insight-runs-v1 xml-insight-suites-v1 xml-insight-testcases-v1 xml-insight-steps-v1 xml-insight-messages-v1 xml-insight-errors-v1 xml-insight-plan-status-v1; do
  count="$(curl -fsS "http://127.0.0.1:${ES_HOST_PORT:-9200}/${idx}/_count" 2>/dev/null | sed -n 's/.*"count":\([0-9]*\).*/\1/p' || true)"
  echo "  ${idx}: ${count:-0}"
done

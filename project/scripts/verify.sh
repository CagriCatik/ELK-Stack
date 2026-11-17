#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_DIR}"

echo "=== Verifying Elasticsearch Indexing & Running Test Suite ==="
docker compose run --rm tools verify --min-runs 1 --min-testcases 1 --min-steps 1 --min-errors 0 --min-plan-slots 0 --timeout 60
docker compose run --rm --entrypoint pytest tools -v

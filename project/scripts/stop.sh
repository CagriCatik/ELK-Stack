#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_DIR}"

echo "Stopping XML Insight Lab containers (persistent Elasticsearch volume preserved)..."
docker compose down
echo "Stopped. Run ./scripts/demo.sh or 'docker compose up -d' to resume."

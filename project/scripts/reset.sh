#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_DIR}"

if [[ "${1:-}" != "--yes" ]]; then
  echo "WARNING: This destructive reset will stop all containers, DELETE the"
  echo "         persistent Elasticsearch volume (esdata), and remove generated"
  echo "         data under ./data/generated, ./data/fixtures, and ./data/plan."
  echo ""
  read -r -p "Type 'RESET' to confirm: " confirm
  if [[ "${confirm}" != "RESET" ]]; then
    echo "Aborted."
    exit 1
  fi
fi

docker compose down -v --remove-orphans
rm -rf "${PROJECT_DIR}/data/generated" "${PROJECT_DIR}/data/fixtures" "${PROJECT_DIR}/data/plan"
echo "Reset complete: containers, Elasticsearch volume, and generated data removed."

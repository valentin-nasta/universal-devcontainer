#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OVERRIDE_FILE="$REPO_ROOT/.devcontainer/devcontainer.local.json"

if [[ -f "$OVERRIDE_FILE" ]]; then
  rm -f "$OVERRIDE_FILE"
  echo "[universal-devcontainer] Removed override: $OVERRIDE_FILE"
  echo "Hint: Run 'Dev Containers: Reopen in Container' if a window is open."
else
  echo "[universal-devcontainer] No override found at: $OVERRIDE_FILE"
fi


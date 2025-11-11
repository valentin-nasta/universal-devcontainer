#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(pwd)"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_JSON="$REPO_ROOT/.devcontainer/devcontainer.json"

echo "[universal-devcontainer] Config: $CONFIG_JSON"
echo "[universal-devcontainer] Workspace: $PROJECT_DIR"

if command -v devcontainer >/dev/null 2>&1 && devcontainer --help 2>/dev/null | grep -qw "open"; then
  echo "[universal-devcontainer] Launching via Dev Containers CLI (open)..."
  exec devcontainer open --config "$CONFIG_JSON" --workspace-folder "$PROJECT_DIR"
fi

echo "[universal-devcontainer] Dev Containers CLI 'open' not available. Using fallback: project-level extends."

PROJ_DEV_DIR="$PROJECT_DIR/.devcontainer"
mkdir -p "$PROJ_DEV_DIR"

# Compute relative path from project dir to config json for extends:file:<relative>
REL_CFG=$(python3 - <<'PY' "$CONFIG_JSON" "$PROJECT_DIR"
import os,sys
config=sys.argv[1]
project=sys.argv[2]
print(os.path.relpath(config, project))
PY
)

PARENT_DIR=$(dirname "$REL_CFG")
cat > "$PROJ_DEV_DIR/devcontainer.json" <<EOF
{
  "name": "$(basename "$PROJECT_DIR")",
  "extends": [
    "file:$PARENT_DIR"
  ]
}
EOF
echo "[universal-devcontainer] Wrote: $PROJ_DEV_DIR/devcontainer.json (extends current repo config)"
echo "Opening project in VS Code; choose 'Dev Containers: Reopen in Container' if prompted."
exec code "$PROJECT_DIR"

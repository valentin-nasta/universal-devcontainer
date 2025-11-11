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

echo "[universal-devcontainer] Dev Containers CLI 'open' not available. Using fallback override."

LOCAL_JSON="$REPO_ROOT/.devcontainer/devcontainer.local.json"
mkdir -p "$REPO_ROOT/.devcontainer"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
json_escape() { printf '%s' "$1" | sed -e 's/\\\\/\\\\\\\\/g' -e 's/\"/\\\"/g'; }
PD_ESC="$(json_escape "$PROJECT_DIR")"
PN_ESC="$(json_escape "$PROJECT_NAME")"
cat > "$LOCAL_JSON" <<EOF
{
  "mounts": [
    "source=$PD_ESC,target=/workspaces/$PN_ESC,type=bind,consistency=cached"
  ],
  "workspaceFolder": "/workspaces/$PN_ESC"
}
EOF
echo "[universal-devcontainer] Wrote override: $LOCAL_JSON"
echo "Next: In VS Code, run 'Dev Containers: Reopen in Container'."
exec code "$REPO_ROOT"

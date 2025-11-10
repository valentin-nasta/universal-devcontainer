#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 1 ]]; then echo "Usage: $0 <path|git-url>"; exit 1; fi
if [[ "$1" =~ ^https?://|git@ ]]; then
  TMP="${HOME}/.cache/universal-dev/$(date +%s)"; mkdir -p "$(dirname "$TMP")"
  git clone --depth=1 "$1" "$TMP"; PROJECT_DIR="$TMP"
else
  PROJECT_DIR="$(cd "$1" && pwd)"
fi
export PROJECT_DIR PROJECT_NAME="$(basename "$PROJECT_DIR")"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Opening devcontainer v2-bypass at $REPO_ROOT with project: $PROJECT_DIR"
code "$REPO_ROOT"

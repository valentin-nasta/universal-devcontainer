#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
export PROJECT_DIR PROJECT_NAME
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Opening devcontainer v2-bypass at $REPO_ROOT with project: $PROJECT_DIR"
code "$REPO_ROOT"

#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(pwd)"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJ_NAME="$(basename "$PROJECT_DIR")"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Universal Dev Container - Current Directory Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Project: $PROJ_NAME"
echo "  Path:    $PROJECT_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create minimal devcontainer configuration with extends
PROJ_DEV_DIR="$PROJECT_DIR/.devcontainer"
mkdir -p "$PROJ_DEV_DIR"

# Calculate relative path for file: extends (macOS/Linux compatible)
if command -v python3 >/dev/null 2>&1; then
  REL_PATH=$(python3 -c "import os; print(os.path.relpath('$REPO_ROOT', '$PROJECT_DIR'))")
else
  # Fallback: use GNU realpath if available
  REL_PATH=$(realpath --relative-to="$PROJECT_DIR" "$REPO_ROOT" 2>/dev/null || echo "../../universal-devcontainer")
fi

# Create the extends configuration (using file: path for reliability)
cat > "$PROJ_DEV_DIR/devcontainer.json" <<EOF
{
  "name": "$PROJ_NAME",
  "extends": "file:$REL_PATH/.devcontainer/devcontainer.json"
}
EOF

echo "✓ Created .devcontainer/devcontainer.json"
echo "  Strategy: extends file:$REL_PATH/.devcontainer/devcontainer.json"

# Note: Using file: path instead of github: because the base config
# contains a Dockerfile with relative path that only works with file: extends

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  1. Opening project in VS Code..."
echo "  2. When prompted, click 'Reopen in Container'"
echo "  3. Wait for container to build (first time only)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

exec code "$PROJECT_DIR"

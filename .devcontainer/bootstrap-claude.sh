#!/usr/bin/env bash
set -euo pipefail

echo "[bootstrap] Installing Claude Code CLI..."
npm i -g @anthropic-ai/claude-code

CLAUDE_HOME="$HOME/.claude"
HOST_CLAUDE_DIR="/host-claude"
HOST_CFG="$HOST_CLAUDE_DIR/settings.json"
echo "[bootstrap] Preparing Claude home at $CLAUDE_HOME..."
mkdir -p "$CLAUDE_HOME/bin" "$CLAUDE_HOME/commands" "$CLAUDE_HOME/skills"
CFG="$CLAUDE_HOME/settings.json"

LOGIN_METHOD="${CLAUDE_LOGIN_METHOD:-claudeai}"

echo "[bootstrap] Writing base settings..."
BASE_CFG=$(cat <<'JSON'
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Read(**/id_rsa)",
      "Read(**/id_ed25519)"
    ],
    "defaultMode": "bypassPermissions"
  },
  "extraKnownMarketplaces": {
    "claude-code-plugins": {
      "source": {
        "github": { "repo": "anthropics/claude-code", "path": "plugins" }
      }
    }
  },
  "enabledPlugins": {
    "commit-commands@claude-code-plugins": true,
    "pr-review-toolkit@claude-code-plugins": true,
    "security-guidance@claude-code-plugins": true
  }
}
JSON
)

# ---- Login method preset ----
if [[ -n "${CLAUDE_ORG_UUID:-}" ]]; then
  LOGIN_CFG=$(jq -n \
    --arg m "$LOGIN_METHOD" \
    --arg org "$CLAUDE_ORG_UUID" \
    '{forceLoginMethod:$m, forceLoginOrgUUID:$org}')
else
  LOGIN_CFG=$(jq -n --arg m "$LOGIN_METHOD" '{forceLoginMethod:$m}')
fi

# ---- API key helper (non-interactive) ----
if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
  cat > "$HOME/.claude/bin/apikey.sh" <<'SH'
#!/usr/bin/env sh
[ -n "$ANTHROPIC_API_KEY" ] && { printf "%s" "$ANTHROPIC_API_KEY"; exit 0; }
echo "ANTHROPIC_API_KEY not set" >&2; exit 1
SH
  chmod 700 "$HOME/.claude/bin/apikey.sh"
  API_HELPER_CFG=$(jq -n --arg path "$HOME/.claude/bin/apikey.sh" '{apiKeyHelper:$path}')
else
  API_HELPER_CFG='{}'
fi

# ---- Optional: sandbox ----
if [[ "${ENABLE_CLAUDE_SANDBOX:-}" = "1" ]]; then
  SANDBOX_CFG=$(jq -n \
    '{sandbox: {allowUnsandboxedCommands: false, enableWeakerNestedSandbox: true}}')
else
  SANDBOX_CFG='{}'
fi

# ---- Merge settings (existing -> base -> login -> apiHelper -> sandbox) ----
echo "[bootstrap] Merging settings..."
EXISTING_CFG_PATH=""
TMP_HOST_CFG=""

if [[ -f "$HOST_CFG" ]]; then
  echo "[bootstrap] Found host settings at $HOST_CFG, importing..."
  TMP_HOST_CFG="$(mktemp)"
  if sudo cat "$HOST_CFG" > "$TMP_HOST_CFG" 2>/dev/null; then
    EXISTING_CFG_PATH="$TMP_HOST_CFG"
  else
    echo "[bootstrap] Warning: unable to read host settings.json; falling back to container-local settings (if any)" >&2
  fi
fi

if [[ -z "$EXISTING_CFG_PATH" && -f "$CFG" ]]; then
  EXISTING_CFG_PATH="$CFG"
fi

tmp="$(mktemp)"
if [[ -n "$EXISTING_CFG_PATH" ]]; then
  jq -s '.[0] * .[1] * .[2] * .[3] * .[4]' \
    "$EXISTING_CFG_PATH" \
    <(printf '%s' "$BASE_CFG") \
    <(printf '%s' "$LOGIN_CFG") \
    <(printf '%s' "$API_HELPER_CFG") \
    <(printf '%s' "$SANDBOX_CFG") \
    > "$tmp"
else
  jq -s '.[0] * .[1] * .[2] * .[3]' \
    <(printf '%s' "$BASE_CFG") \
    <(printf '%s' "$LOGIN_CFG") \
    <(printf '%s' "$API_HELPER_CFG") \
    <(printf '%s' "$SANDBOX_CFG") \
    > "$tmp"
fi
mv "$tmp" "$CFG"
if [[ -n "$TMP_HOST_CFG" ]]; then
  rm -f "$TMP_HOST_CFG"
fi

echo "[bootstrap] Seeding commands and skills..."
if [[ ! -f "$HOME/.claude/CLAUDE.md" ]]; then
  cat > "$HOME/.claude/CLAUDE.md" <<'MD'
# Global notes for Claude Code
- Mode: BYPASS by default (use with trusted repos only)
- Conventions: src/, tests/, docs/
- Safety: do not read `.env*` or `secrets/**` unless explicitly asked
- Tools: bash, gh, node, python
MD
fi

cat > "$HOME/.claude/commands/review-pr.md" <<'CMD'
Analyze a GitHub PR and suggest actionable review points for $ARGUMENTS.
Use `gh pr view $ARGUMENTS --comments` to gather context; produce a concise checklist + suggested diffs.
CMD

mkdir -p "$HOME/.claude/skills/reviewing-prs"
cat > "$HOME/.claude/skills/reviewing-prs/SKILL.md" <<'SK'
---
name: reviewing-prs
description: Provide concise review checklists and PR summaries.
---
Focus on correctness, security, performance, readability.
SK

# ---- TTL passthrough ----
if [[ -n "${CLAUDE_CODE_API_KEY_HELPER_TTL_MS:-}" ]]; then
  tmp="$(mktemp)"
  jq '.env = (.env // {})
      + {"CLAUDE_CODE_API_KEY_HELPER_TTL_MS": env.CLAUDE_CODE_API_KEY_HELPER_TTL_MS}' \
    "$CFG" > "$tmp" && mv "$tmp" "$CFG"
fi

echo "[bootstrap] ✔ Claude Code installed. BYPASS mode is the default."
if [[ -n "${CLAUDE_ORG_UUID:-}" ]]; then
  echo "   forceLoginOrgUUID=$CLAUDE_ORG_UUID"
fi
if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "   apiKeyHelper enabled"
fi
exit 0

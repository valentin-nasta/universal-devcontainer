#!/usr/bin/env bash
# Switch Claude Code permission mode quickly.
# Usage:
#   switch-mode.sh bypass
#   switch-mode.sh safe
#   switch-mode.sh custom <mode-string>
set -euo pipefail
CFG="$HOME/.claude/settings.json"
mode="${1:-}"
if [[ -z "$mode" ]]; then
  echo "Usage: $0 {bypass|safe|custom <mode>}"; exit 1
fi
tmp="$(mktemp)"
case "$mode" in
  bypass)
    # Remove any enterprise policy-like block (if present at user level)
    jq 'del(.permissions.disableBypassPermissionsMode) | .permissions.defaultMode = "bypassPermissions"'       "$CFG" > "$tmp" && mv "$tmp" "$CFG"
    echo "Switched to BYPASS mode."
    ;;
  safe)
    # Safer default: accept edits and explicitly disable bypass
    jq '.permissions.defaultMode = "acceptEdits" | .permissions.disableBypassPermissionsMode = "disable"'       "$CFG" > "$tmp" && mv "$tmp" "$CFG"
    echo "Switched to SAFE mode (acceptEdits + disable bypass)."
    ;;
  custom)
    val="${2:-}"
    if [[ -z "$val" ]]; then echo "Provide a custom mode value"; exit 1; fi
    jq --arg v "$val" '.permissions.defaultMode = $v' "$CFG" > "$tmp" && mv "$tmp" "$CFG"
    echo "Switched to custom mode: $val"
    ;;
  *)
    echo "Unknown mode: $mode"; exit 1;;
esac

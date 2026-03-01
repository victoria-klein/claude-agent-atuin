#!/bin/bash
set -euo pipefail

echo "=== Test: hooks.json is valid ==="

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Valid JSON
if ! jq empty "${PLUGIN_DIR}/hooks/hooks.json" 2>/dev/null; then
  echo "FAIL: hooks.json is not valid JSON"
  exit 1
fi
echo "PASS: hooks.json is valid JSON"

# Has SessionStart hook
if ! jq -e '.hooks.SessionStart' "${PLUGIN_DIR}/hooks/hooks.json" > /dev/null 2>&1; then
  echo "FAIL: missing SessionStart hook"
  exit 1
fi
echo "PASS: SessionStart hook present"

# Has SubagentStart hook
if ! jq -e '.hooks.SubagentStart' "${PLUGIN_DIR}/hooks/hooks.json" > /dev/null 2>&1; then
  echo "FAIL: missing SubagentStart hook"
  exit 1
fi
echo "PASS: SubagentStart hook present"

# No removed hooks remain
for removed in SessionEnd PostToolUse UserPromptSubmit; do
  if jq -e ".hooks.${removed}" "${PLUGIN_DIR}/hooks/hooks.json" > /dev/null 2>&1; then
    echo "FAIL: removed hook '${removed}' still present"
    exit 1
  fi
  echo "PASS: removed hook '${removed}' is gone"
done

# Scripts referenced in hooks exist
SCRIPTS=$(jq -r '.. | .command? // empty' "${PLUGIN_DIR}/hooks/hooks.json" | sed "s|\${CLAUDE_PLUGIN_ROOT}|${PLUGIN_DIR}|g")
for script in $SCRIPTS; do
  if [ ! -f "$script" ]; then
    echo "FAIL: hook script not found: $script"
    exit 1
  fi
  if [ ! -x "$script" ]; then
    echo "FAIL: hook script not executable: $script"
    exit 1
  fi
  echo "PASS: $(basename "$script") exists and is executable"
done

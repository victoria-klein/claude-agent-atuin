#!/bin/bash
set -euo pipefail

echo "=== Test: subagent-start.sh ==="

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="${PLUGIN_DIR}/scripts/subagent-start.sh"

# Set up mock environment
export CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR"
CLAUDE_ENV_FILE=$(mktemp)
export CLAUDE_ENV_FILE

# Pipe mock input with session_id and agent_id
OUTPUT=$(echo '{"session_id":"test-session-456","agent_id":"sub-agent-789"}' | "$SCRIPT")

# Check ATUIN_AGENT_ID with hierarchical format
if ! grep -q 'ATUIN_AGENT_ID="claude-code/session-test-session-456/subagent-sub-agent-789"' "$CLAUDE_ENV_FILE"; then
  echo "FAIL: ATUIN_AGENT_ID not set with hierarchical format in env file"
  cat "$CLAUDE_ENV_FILE"
  rm -f "$CLAUDE_ENV_FILE"
  exit 1
fi
echo "PASS: ATUIN_AGENT_ID set with hierarchical format"

# Check ATUIN_SESSION is present and non-empty
if ! grep -q 'ATUIN_SESSION=.' "$CLAUDE_ENV_FILE"; then
  echo "FAIL: ATUIN_SESSION not set in env file"
  cat "$CLAUDE_ENV_FILE"
  rm -f "$CLAUDE_ENV_FILE"
  exit 1
fi
echo "PASS: ATUIN_SESSION set in env file"

# Check PATH includes plugin bin dir
if ! grep -q "PATH=.*${PLUGIN_DIR}/bin" "$CLAUDE_ENV_FILE"; then
  echo "FAIL: PATH not updated in env file"
  cat "$CLAUDE_ENV_FILE"
  rm -f "$CLAUDE_ENV_FILE"
  exit 1
fi
echo "PASS: PATH includes plugin bin directory"

# Check BASH_ENV points to claude-bash-init.sh
if ! grep -q "BASH_ENV=.*claude-bash-init.sh" "$CLAUDE_ENV_FILE"; then
  echo "FAIL: BASH_ENV not set in env file"
  cat "$CLAUDE_ENV_FILE"
  rm -f "$CLAUDE_ENV_FILE"
  exit 1
fi
echo "PASS: BASH_ENV points to claude-bash-init.sh"

# Check JSON output is valid
if ! echo "$OUTPUT" | jq empty 2>/dev/null; then
  echo "FAIL: output is not valid JSON"
  echo "$OUTPUT"
  rm -f "$CLAUDE_ENV_FILE"
  exit 1
fi
echo "PASS: output is valid JSON"

CONTEXT=$(echo "$OUTPUT" | jq -r '.hookSpecificOutput.additionalContext')
if [ -z "$CONTEXT" ] || [ "$CONTEXT" = "null" ]; then
  echo "FAIL: no additionalContext in output"
  rm -f "$CLAUDE_ENV_FILE"
  exit 1
fi
echo "PASS: additionalContext present"

# Check context mentions key commands
for keyword in "agent-atuin memory show" "agent-atuin memory run" "Do NOT use"; do
  if ! echo "$CONTEXT" | grep -qF "$keyword"; then
    echo "FAIL: context missing keyword: $keyword"
    rm -f "$CLAUDE_ENV_FILE"
    exit 1
  fi
  echo "PASS: context mentions '$keyword'"
done

rm -f "$CLAUDE_ENV_FILE"

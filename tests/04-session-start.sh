#!/bin/bash
set -euo pipefail

echo "=== Test: session-start.sh ==="

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="${PLUGIN_DIR}/scripts/session-start.sh"

# Set up mock environment
export CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR"
CLAUDE_ENV_FILE=$(mktemp)
export CLAUDE_ENV_FILE

# Pipe mock input
OUTPUT=$(echo '{"session_id":"test-session-123","cwd":"/tmp"}' | "$SCRIPT")

# Check env file was written
if ! grep -q 'ATUIN_AGENT_ID="claude-code/session-test-session-123"' "$CLAUDE_ENV_FILE"; then
  echo "FAIL: ATUIN_AGENT_ID not set in env file"
  cat "$CLAUDE_ENV_FILE"
  rm -f "$CLAUDE_ENV_FILE"
  exit 1
fi
echo "PASS: ATUIN_AGENT_ID set correctly"

if ! grep -q "PATH=.*${PLUGIN_DIR}/bin" "$CLAUDE_ENV_FILE"; then
  echo "FAIL: PATH not updated in env file"
  cat "$CLAUDE_ENV_FILE"
  rm -f "$CLAUDE_ENV_FILE"
  exit 1
fi
echo "PASS: PATH includes plugin bin directory"

if ! grep -q 'ATUIN_SESSION' "$CLAUDE_ENV_FILE"; then
  echo "FAIL: ATUIN_SESSION not set in env file"
  cat "$CLAUDE_ENV_FILE"
  rm -f "$CLAUDE_ENV_FILE"
  exit 1
fi
echo "PASS: ATUIN_SESSION set in env file"

if ! grep -q "BASH_ENV=.*claude-bash-init.sh" "$CLAUDE_ENV_FILE"; then
  echo "FAIL: BASH_ENV not set in env file"
  cat "$CLAUDE_ENV_FILE"
  rm -f "$CLAUDE_ENV_FILE"
  exit 1
fi
echo "PASS: BASH_ENV points to claude-bash-init.sh"

# Check JSON output
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

# Check context mentions key things
for keyword in "agent-atuin memory create" "/atuin:remember" "/atuin:recall" "/atuin:replay" "(atuin:<id>)"; do
  if ! echo "$CONTEXT" | grep -qF "$keyword"; then
    echo "FAIL: context missing keyword: $keyword"
    rm -f "$CLAUDE_ENV_FILE"
    exit 1
  fi
  echo "PASS: context mentions '$keyword'"
done

rm -f "$CLAUDE_ENV_FILE"

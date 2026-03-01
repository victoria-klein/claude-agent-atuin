#!/bin/bash
set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')

# Inject environment variables for all subsequent Bash calls
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  cat >> "$CLAUDE_ENV_FILE" <<EOF
export ATUIN_AGENT_ID="claude-code/session-${SESSION_ID}"
export ATUIN_SESSION=\$(${CLAUDE_PLUGIN_ROOT}/bin/agent-atuin uuid)
export PATH="${CLAUDE_PLUGIN_ROOT}/bin:\$PATH"
export BASH_ENV="${CLAUDE_PLUGIN_ROOT}/scripts/claude-bash-init.sh"
EOF
fi

# Inject context
cat <<'HOOK'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Atuin memory is active. Skills: /atuin:remember to create memories with linked commands, /atuin:recall to search past memories, /atuin:replay to re-run commands from a memory.\n\nWhen saving auto-memories (writing to MEMORY.md or topic files), also create a linked atuin memory:\n  agent-atuin memory create \"<description>\" --link-last <N> --json\nUse --link-last 5 for short learnings, 10-20 for longer investigations. Include the returned id in your markdown as (atuin:<id>) so the commands that produced the learning are replayable. Only create atuin memories when there are associated shell commands worth linking."
  }
}
HOOK

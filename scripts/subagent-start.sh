#!/bin/bash
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // empty')

ATUIN="${CLAUDE_PLUGIN_ROOT}/bin/agent-atuin"

# Inject environment variables for the subagent's Bash calls
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  cat >> "$CLAUDE_ENV_FILE" <<EOF
export ATUIN_SESSION=$($ATUIN uuid)
export ATUIN_AGENT_ID="claude-code/session-${SESSION_ID}/subagent-${AGENT_ID}"
export PATH="${CLAUDE_PLUGIN_ROOT}/bin:\$PATH"
export BASH_ENV="${CLAUDE_PLUGIN_ROOT}/scripts/claude-bash-init.sh"
EOF
fi

# Inject context so the subagent knows about atuin memory capabilities
cat <<'HOOK'
{
  "hookSpecificOutput": {
    "hookEventName": "SubagentStart",
    "additionalContext": "Atuin memory is available in this subagent. The `agent-atuin` binary is in PATH.\n\nUseful commands:\n  agent-atuin memory show <id> --json    # show a memory with linked commands\n  agent-atuin memory run <id> --dry-run   # preview replay of linked commands\n  agent-atuin memory run <id> --here      # replay commands in current directory\n  agent-atuin memory search \"query\" --json # search memories\n  agent-atuin memory create \"desc\" --link-last <N> --json  # create a memory\n\nDo NOT use `cargo run` — use `agent-atuin` directly."
  }
}
HOOK

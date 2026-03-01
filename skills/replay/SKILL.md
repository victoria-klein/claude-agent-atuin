---
name: replay
description: Preview and optionally re-run the commands linked to an atuin memory. Use when the user wants to repeat a workflow from a past session or verify a sequence of commands.
user-invocable: true
allowed-tools: Bash
argument-hint: "<memory-id> [--dry-run]"
---

Replay commands from an atuin memory.

1. First, always preview what would be run:
```bash
agent-atuin memory run $ARGUMENTS --dry-run
```

2. Show the user the command list with original working directories and ask for confirmation before executing.

3. If the user confirms, run with:
```bash
agent-atuin memory run $ARGUMENTS --keep-going
```

Use `--here` if the user wants to run in the current directory instead of the original working directories:
```bash
agent-atuin memory run $ARGUMENTS --here --keep-going
```

IMPORTANT: Always show the dry-run output first. Never execute commands without user confirmation.

---
name: remember
description: Create a structured atuin memory with linked commands. Use when the user wants to save a memory that links to specific shell commands they ran.
user-invocable: true
allowed-tools: Bash
argument-hint: "<description> [--link-last N]"
---

Create an atuin memory using the bundled binary. Parse the user's intent to determine:

1. **Description**: What to remember (required)
2. **Command linking**: How many recent commands to link (`--link-last N`, default 5)

Run:
```bash
agent-atuin memory create "$ARGUMENTS" --link-last 5 --json
```

After creation, show the user the memory ID and what was linked.

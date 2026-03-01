---
name: recall
description: Search atuin memories by description or command content. Use when the user asks about past work, wants to find how they solved a problem before, or needs context from previous sessions.
user-invocable: true
allowed-tools: Bash
argument-hint: "<search query>"
---

Search atuin memories for relevant past context.

1. Search by description:
```bash
agent-atuin memory search "$ARGUMENTS" --json
```

2. If results are found, show them in a readable format. For each interesting result, fetch details:
```bash
agent-atuin memory show <id> --json
```

3. The `show` output includes linked commands with full text, exit codes, and durations. Summarize the key findings for the user.

4. If the search query looks like a command, also try:
```bash
agent-atuin memory search "$ARGUMENTS" --command "$ARGUMENTS" --json
```

Present results organized by relevance, showing:
- Memory description
- When it was created
- Git context (repo, branch) if present
- Key linked commands and their outcomes

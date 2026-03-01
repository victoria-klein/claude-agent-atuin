# claude-agent-atuin

Claude Code plugin for [agent-atuin](https://github.com/victoria-klein/agent-atuin). Provides shell command history tracking and searchable memories on top of Claude Code's built-in memory system.

## Structure
```
claude-agent-atuin/
├── .claude-plugin/plugin.json   # Plugin manifest
├── settings.json                # Plugin config (currently empty)
├── hooks/hooks.json             # Hook registration (SessionStart, SubagentStart)
├── scripts/
│   ├── session-start.sh         # Main session setup + context injection
│   ├── subagent-start.sh        # Subagent setup + context injection
│   └── claude-bash-init.sh      # Non-interactive bash preexec/precmd hooks
├── skills/
│   ├── remember/SKILL.md        # /atuin:remember — create memories with linked commands
│   ├── recall/SKILL.md          # /atuin:recall — search past memories
│   └── replay/SKILL.md          # /atuin:replay — preview and re-run linked commands
├── bin/
│   └── agent-atuin              # Binary (downloaded by build.sh, gitignored)
├── build.sh                     # Downloads release binary (or falls back to PATH)
└── tests/
    ├── run-all.sh               # Test runner (sequential: 01 through 06)
    ├── 01-build.sh              # Build/download verification
    ├── 02-binary.sh             # Binary smoke test
    ├── 03-hooks-json.sh         # Hook registration validation
    ├── 04-session-start.sh      # Session hook output validation
    ├── 04b-subagent-start.sh    # Subagent hook output validation
    ├── 04c-bash-init.sh         # Bash init script structure validation
    ├── 05-memory-flow.sh        # End-to-end memory CRUD + dry-run
    └── 06-skills.sh             # Skill frontmatter and content validation
```

## Binary

- Path: `${CLAUDE_PLUGIN_ROOT}/bin/agent-atuin`
- Install: `./build.sh` downloads a release binary (or symlinks one from PATH)
- The binary is built from the [agent-atuin](https://github.com/victoria-klein/agent-atuin) Rust workspace (`cargo build --release -p atuin`)
- Provides all memory subcommands: create, list, search, show, delete, link, run, children, ancestors, tree

## Hooks

Two lifecycle hooks registered in `hooks/hooks.json`:

### SessionStart (`session-start.sh`)
- Injects env vars via `CLAUDE_ENV_FILE`: `ATUIN_AGENT_ID`, `ATUIN_SESSION`, `PATH`, `BASH_ENV`
- Returns `additionalContext` JSON telling the main agent about available skills and memory workflow

### SubagentStart (`subagent-start.sh`)
- Same env var injection with hierarchical agent ID (`session-{id}/subagent-{id}`)
- Returns `additionalContext` JSON with command reference so subagents know to use `agent-atuin` directly

Both hooks must exit 0 and complete within 10 seconds.

## Shell scripts
- `#!/bin/bash` with `set -euo pipefail`
- Scripts receive JSON on stdin; parse with `jq`
- `claude-bash-init.sh` is sourced via `BASH_ENV` — implements preexec/precmd for non-interactive bash to track commands with `agent-atuin history start/end`
- Use `2>/dev/null || true` for atuin commands that may fail

## Skills
- Each skill lives in `skills/<name>/SKILL.md`
- Skills define prompt templates expanded when a user invokes `/atuin:<name>`
- All skills use `agent-atuin` binary (never bare `atuin` or `$ATUIN_BIN`)
- `/atuin:remember` — create memories, default links last 5 commands
- `/atuin:recall` — full-text search by description or command pattern
- `/atuin:replay` — always shows dry-run first, requires user confirmation before execution

## Testing
- Run: `./tests/run-all.sh`
- Tests are sequential (01 through 06), covering build, binary, hooks, session setup, end-to-end memory flow, and skill validation
- Tests verify skills use `agent-atuin` (not bare `atuin`) and have correct frontmatter
- **Never source `claude-bash-init.sh` in tests** — its DEBUG trap fallback fork-bombs when `agent-atuin` calls trigger recursive preexec hooks. Test it via content inspection (`grep`) instead.

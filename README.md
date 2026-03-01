# claude-agent-atuin

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin that gives **Claude persistent, searchable and executable memory** backed by [agent-atuin](https://github.com/victoria-klein/agent-atuin). Shell commands run during a session are automatically tracked, and memories can be created that link back to the exact commands that produced them.

## Features

- **Automatic command tracking** — every shell command Claude runs is recorded via atuin history, with no extra effort from the user.
- **Structured memories** — create memories with descriptions and linked commands so you can recall *how* something was done, not just *that* it was done.
- **Cross-session recall** — search past memories by description or command content across all previous sessions.
- **Replay workflows** — preview and re-run command sequences from past memories with a dry-run safety step.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) with plugin support
- `jq` (used by hook scripts)
- macOS (Apple Silicon or Intel) or Linux (x86_64 or aarch64)

## Installation

Clone this repo into your Claude Code plugins directory:

```sh
git clone https://github.com/victoria-klein/claude-agent-atuin.git
```

Then run the build script to download the `agent-atuin` binary:

```sh
cd claude-agent-atuin
./build.sh
```

This downloads the appropriate binary from the [agent-atuin v0.1.0 release](https://github.com/victoria-klein/agent-atuin/releases/tag/v0.1.0). If the download fails, it falls back to symlinking `agent-atuin` or `atuin` from your PATH.

## Skills

The plugin provides three slash commands:

| Command | Description |
|---|---|
| `/atuin:remember` | Create a memory linked to recent shell commands |
| `/atuin:recall` | Search past memories by description or command pattern |
| `/atuin:replay` | Preview and re-run commands from a past memory |

### `/atuin:remember`

Saves a structured memory and links it to recent commands (last 5 by default). Use it after completing a task you might want to reference later.

### `/atuin:recall`

Full-text search across all memories. Useful for finding how you solved a problem before or retrieving context from a previous session.

### `/atuin:replay`

Shows a dry-run of the commands linked to a memory, then asks for confirmation before executing. Useful for repeating multi-step workflows.

## How it works

The plugin registers two lifecycle hooks:

- **SessionStart** — sets up environment variables (`ATUIN_AGENT_ID`, `ATUIN_SESSION`, `PATH`, `BASH_ENV`) and injects context telling Claude about available skills.
- **SubagentStart** — same setup for subagents, with hierarchical agent IDs for traceability.

A bash init script (`claude-bash-init.sh`) is loaded via `BASH_ENV` to install `preexec`/`precmd` hooks that automatically call `agent-atuin history start/end` around every command.

## Testing

```sh
./tests/run-all.sh
```

Runs 8 test suites covering build, binary, hooks, session setup, bash init, end-to-end memory CRUD, and skill validation.

## License

MIT

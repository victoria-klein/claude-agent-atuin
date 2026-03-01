#!/bin/bash
set -euo pipefail

echo "=== Test: Binary works ==="

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ATUIN="${PLUGIN_DIR}/bin/agent-atuin"

if [ ! -x "$ATUIN" ]; then
  echo "FAIL: agent-atuin binary not found — run 01-build.sh first"
  exit 1
fi

# Basic help
"$ATUIN" --help > /dev/null
echo "PASS: agent-atuin --help"

# Memory subcommand exists
"$ATUIN" memory --help > /dev/null
echo "PASS: agent-atuin memory --help"

# Memory subcommands exist
for cmd in create list search show delete run; do
  "$ATUIN" memory "$cmd" --help > /dev/null
  echo "PASS: agent-atuin memory $cmd --help"
done

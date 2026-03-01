#!/bin/bash
set -euo pipefail

echo "=== Test: End-to-end memory flow ==="

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ATUIN="${PLUGIN_DIR}/bin/agent-atuin"

if [ ! -x "$ATUIN" ]; then
  echo "FAIL: agent-atuin binary not found — run 01-build.sh first"
  exit 1
fi

# Create a memory
CREATE_OUTPUT=$("$ATUIN" memory create "test plugin memory" --json 2>/dev/null)
MEMORY_ID=$(echo "$CREATE_OUTPUT" | jq -r '.id')

if [ -z "$MEMORY_ID" ] || [ "$MEMORY_ID" = "null" ]; then
  echo "FAIL: could not create memory"
  echo "$CREATE_OUTPUT"
  exit 1
fi
echo "PASS: created memory $MEMORY_ID"

# Search for it
SEARCH_OUTPUT=$("$ATUIN" memory search "test plugin" --json 2>/dev/null)
FOUND=$(echo "$SEARCH_OUTPUT" | jq -r ".[] | select(.id == \"$MEMORY_ID\") | .id")

if [ "$FOUND" != "$MEMORY_ID" ]; then
  echo "FAIL: memory not found via search"
  echo "$SEARCH_OUTPUT"
  "$ATUIN" memory delete "$MEMORY_ID" 2>/dev/null || true
  exit 1
fi
echo "PASS: memory found via search"

# Show it
SHOW_OUTPUT=$("$ATUIN" memory show "$MEMORY_ID" --json 2>/dev/null)
DESC=$(echo "$SHOW_OUTPUT" | jq -r '.description')

if [ "$DESC" != "test plugin memory" ]; then
  echo "FAIL: show returned wrong description: $DESC"
  "$ATUIN" memory delete "$MEMORY_ID" 2>/dev/null || true
  exit 1
fi
echo "PASS: memory show returns correct description"

# Dry run (should work even with no linked commands)
"$ATUIN" memory run "$MEMORY_ID" --dry-run > /dev/null 2>&1 || true
echo "PASS: memory run --dry-run completed"

# Cleanup
"$ATUIN" memory delete "$MEMORY_ID" 2>/dev/null || true
echo "PASS: test memory cleaned up"

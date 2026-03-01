#!/bin/bash
set -euo pipefail

echo "=== Test: Skills validation ==="

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

EXPECTED_SKILLS="remember recall replay"

for skill in $EXPECTED_SKILLS; do
  SKILL_FILE="${PLUGIN_DIR}/skills/${skill}/SKILL.md"

  if [ ! -f "$SKILL_FILE" ]; then
    echo "FAIL: skill file missing: $SKILL_FILE"
    exit 1
  fi
  echo "PASS: ${skill}/SKILL.md exists"

  # Check frontmatter has required fields
  if ! grep -q "^name: ${skill}" "$SKILL_FILE"; then
    echo "FAIL: ${skill} missing name in frontmatter"
    exit 1
  fi
  echo "PASS: ${skill} has correct name"

  if ! grep -q "^description:" "$SKILL_FILE"; then
    echo "FAIL: ${skill} missing description in frontmatter"
    exit 1
  fi
  echo "PASS: ${skill} has description"

  if ! grep -q "^user-invocable: true" "$SKILL_FILE"; then
    echo "FAIL: ${skill} not user-invocable"
    exit 1
  fi
  echo "PASS: ${skill} is user-invocable"

  # Check CLI references use agent-atuin, not bare atuin or $ATUIN_BIN
  if grep -q '\$ATUIN_BIN' "$SKILL_FILE"; then
    echo "FAIL: ${skill} still references \$ATUIN_BIN"
    exit 1
  fi
  echo "PASS: ${skill} does not reference \$ATUIN_BIN"

  # Check commands use agent-atuin
  if grep -qE '^\s*atuin ' "$SKILL_FILE" && ! grep -qE '^\s*agent-atuin ' "$SKILL_FILE"; then
    echo "FAIL: ${skill} uses bare 'atuin' instead of 'agent-atuin'"
    exit 1
  fi
  echo "PASS: ${skill} uses agent-atuin for commands"
done

# Check no removed skills remain
for removed in context tree; do
  if [ -d "${PLUGIN_DIR}/skills/${removed}" ]; then
    echo "FAIL: removed skill '${removed}' still exists"
    exit 1
  fi
  echo "PASS: removed skill '${removed}' is gone"
done

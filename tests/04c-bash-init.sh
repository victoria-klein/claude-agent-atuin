#!/bin/bash
set -euo pipefail

echo "=== Test: claude-bash-init.sh ==="

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="${PLUGIN_DIR}/scripts/claude-bash-init.sh"

# Read script content once
CONTENT=$(cat "$SCRIPT")

# Verify idempotency guard exists (early return if already initialized)
if ! echo "$CONTENT" | grep -q '__atuin_initialized.*==.*true'; then
  echo "FAIL: missing idempotency guard (__atuin_initialized check)"
  exit 1
fi
if ! echo "$CONTENT" | grep -q 'return 0'; then
  echo "FAIL: missing idempotency guard (return 0)"
  exit 1
fi
echo "PASS: idempotency guard present"

# Verify __atuin_initialized is set to true
if ! echo "$CONTENT" | grep -q '__atuin_initialized=true'; then
  echo "FAIL: __atuin_initialized=true not set"
  exit 1
fi
echo "PASS: __atuin_initialized set to true"

# Verify __atuin_preexec function is defined
if ! echo "$CONTENT" | grep -q '__atuin_preexec()'; then
  echo "FAIL: __atuin_preexec function not defined"
  exit 1
fi
echo "PASS: __atuin_preexec function defined"

# Verify __atuin_precmd function is defined
if ! echo "$CONTENT" | grep -q '__atuin_precmd()'; then
  echo "FAIL: __atuin_precmd function not defined"
  exit 1
fi
echo "PASS: __atuin_precmd function defined"

# Verify precmd_functions array includes the hook
if ! echo "$CONTENT" | grep -q 'precmd_functions+=.*__atuin_precmd'; then
  echo "FAIL: __atuin_precmd not added to precmd_functions"
  exit 1
fi
echo "PASS: precmd_functions includes __atuin_precmd"

# Verify preexec_functions array includes the hook
if ! echo "$CONTENT" | grep -q 'preexec_functions+=.*__atuin_preexec'; then
  echo "FAIL: __atuin_preexec not added to preexec_functions"
  exit 1
fi
echo "PASS: preexec_functions includes __atuin_preexec"

# Verify the script uses agent-atuin (not bare atuin) for history tracking
# Exclude comments (lines starting with #) from this check
if echo "$CONTENT" | grep -v '^#' | grep -v 'agent-atuin' | grep -q '[^-]atuin history'; then
  echo "FAIL: script uses bare 'atuin' instead of 'agent-atuin'"
  exit 1
fi
echo "PASS: uses agent-atuin for history commands"

# Verify ATUIN_SESSION is initialized if missing
if ! echo "$CONTENT" | grep -q 'ATUIN_SESSION.*agent-atuin uuid'; then
  echo "FAIL: ATUIN_SESSION not initialized via agent-atuin uuid"
  exit 1
fi
echo "PASS: ATUIN_SESSION initialized via agent-atuin uuid"

# Verify preexec calls history start
if ! echo "$CONTENT" | grep -q 'agent-atuin history start'; then
  echo "FAIL: preexec does not call history start"
  exit 1
fi
echo "PASS: preexec calls agent-atuin history start"

# Verify precmd calls history end
if ! echo "$CONTENT" | grep -q 'agent-atuin history end'; then
  echo "FAIL: precmd does not call history end"
  exit 1
fi
echo "PASS: precmd calls agent-atuin history end"

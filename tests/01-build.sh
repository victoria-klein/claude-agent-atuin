#!/bin/bash
set -euo pipefail

echo "=== Test: Build/install plugin ==="

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

"${PLUGIN_DIR}/build.sh"

if [ ! -x "${PLUGIN_DIR}/bin/agent-atuin" ]; then
  echo "FAIL: bin/agent-atuin not found or not executable after build.sh"
  exit 1
fi

echo "PASS: agent-atuin binary available"

#!/bin/bash
set -euo pipefail

echo "Running atuin-memory plugin tests..."
echo

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
PASSED=0
FAILED=0

for test in "$TEST_DIR"/[0-9]*.sh; do
  echo "---"
  if bash "$test"; then
    PASSED=$((PASSED + 1))
  else
    FAILED=$((FAILED + 1))
    echo "FAILED: $(basename "$test")"
  fi
  echo
done

echo "=== Results ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi

echo "All tests passed!"

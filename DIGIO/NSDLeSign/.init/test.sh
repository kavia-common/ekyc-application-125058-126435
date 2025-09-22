#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/ekyc-application-125058-126435/DIGIO/NSDLeSign"
cd "$WORKSPACE"
# Run Jest non-interactively; write test.log
TEST_LOG="$WORKSPACE/test.log"
rm -f "$TEST_LOG"
if [ -d node_modules ] && [ ! -x ./node_modules/.bin/jest ]; then
  echo "ERROR: jest binary missing; run deps-001" >&2
  exit 14
fi
if command -v ./node_modules/.bin/jest >/dev/null 2>&1; then
  ./node_modules/.bin/jest --runInBand --reporters=default > "$TEST_LOG" 2>&1 || true
else
  # fallback to global jest if available
  if command -v jest >/dev/null 2>&1; then
    jest --runInBand --reporters=default > "$TEST_LOG" 2>&1 || true
  else
    echo "WARNING: jest not available; creating placeholder test.log" > "$TEST_LOG"
    echo "NO_TESTS_RUN" >> "$TEST_LOG"
  fi
fi
exit 0

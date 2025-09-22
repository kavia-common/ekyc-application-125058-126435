#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/ekyc-application-125058-126435/DIGIO/NSDLeSign"
LOG="$WORKSPACE/install.log"
cd "$WORKSPACE"
# Ensure npm present
if ! command -v npm >/dev/null 2>&1; then
  echo "ERROR: npm not found on PATH" >&2
  exit 2
fi
# Write minimal log header
printf "install started at %s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$LOG"
# Create package-lock deterministically if missing
if [ ! -f package-lock.json ]; then
  npm i --package-lock-only --no-audit --no-fund >>"$LOG" 2>&1 || (cat "$LOG" >&2; exit 6)
fi
# Install dependencies deterministically
npm ci --no-audit --no-fund >>"$LOG" 2>&1 || (cat "$LOG" >&2; exit 7)
# Verify required local binaries
for bin in serve jest; do
  if [ ! -x "./node_modules/.bin/$bin" ]; then
    echo "ERROR: required binary ./node_modules/.bin/$bin missing; check package.json and run deps-001" | tee -a "$LOG" >&2
    exit 8
  fi
done
printf "install completed at %s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >>"$LOG"
exit 0

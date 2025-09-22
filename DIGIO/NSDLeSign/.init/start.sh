#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/ekyc-application-125058-126435/DIGIO/NSDLeSign"
PORT=${PORT:-3000}
cd "$WORKSPACE"
LOG="$WORKSPACE/validation.log"
PGIDFILE="$WORKSPACE/serve.pgid"
rm -f "$LOG" "$PGIDFILE"
if [ ! -x ./node_modules/.bin/serve ]; then echo "ERROR: local serve binary missing; run deps-001" >&2; exit 13; fi
# Start serve in its own process group so we can kill whole group
setsid ./node_modules/.bin/serve -s build -l "$PORT" > "$LOG" 2>&1 &
PID=$!
# capture process group id
PGID=$(ps -o pgid= -p "$PID" | tr -d ' ' || echo "")
if [ -n "$PGID" ]; then echo "$PGID" > "$PGIDFILE"; fi
# persist PID as well
echo "$PID" > "$WORKSPACE/serve.pid"
exit 0

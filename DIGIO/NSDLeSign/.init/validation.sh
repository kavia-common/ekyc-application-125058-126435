#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/ekyc-application-125058-126435/DIGIO/NSDLeSign"
PORT=${PORT:-3000}
LOG="$WORKSPACE/validation.log"
BUILD_LOG="$WORKSPACE/build.log"
SUMMARY="$WORKSPACE/validation.summary.json"
PGIDFILE="$WORKSPACE/serve.pgid"
HTML_OUT="$WORKSPACE/validation.html"
cd "$WORKSPACE"
rm -f "$LOG" "$BUILD_LOG" "$SUMMARY" "$PGIDFILE" "$HTML_OUT"
# Build
npm run build --if-present > "$BUILD_LOG" 2>&1 || (jq -n --arg e "build_failed" '{build_ok:false,error:$e}' > "$SUMMARY"; cat "$BUILD_LOG" >&2; exit 12)
# Require local serve binary
if [ ! -x ./node_modules/.bin/serve ]; then echo "ERROR: local serve binary missing; run deps-001" >&2; exit 13; fi
# Start serve in its own process group so we can kill whole group
setsid ./node_modules/.bin/serve -s build -l "$PORT" > "$LOG" 2>&1 &
PID=$!
# capture process group id
PGID=$(ps -o pgid= -p "$PID" | tr -d ' ' || echo "")
if [ -n "$PGID" ]; then echo "$PGID" > "$PGIDFILE"; fi
# Readiness probe: prefer curl, fallback to nc
TRIES=0
SUCCESS=1
if command -v curl >/dev/null 2>&1; then
  until curl -sSf --max-time 3 "http://localhost:$PORT" -o "$HTML_OUT" 2>/dev/null || [ $TRIES -ge 60 ]; do sleep 1; TRIES=$((TRIES+1)); done
  if [ $TRIES -lt 60 ]; then SUCCESS=0; fi
elif command -v nc >/dev/null 2>&1; then
  until nc -z localhost "$PORT" >/dev/null 2>&1 || [ $TRIES -ge 60 ]; do sleep 1; TRIES=$((TRIES+1)); done
  if [ $TRIES -lt 60 ]; then
    # try to capture body if curl exists; otherwise nc confirmed port
    if command -v curl >/dev/null 2>&1; then
      curl -sSf --max-time 3 "http://localhost:$PORT" -o "$HTML_OUT" 2>/dev/null || true
    fi
    SUCCESS=0
  fi
else
  echo "ERROR: neither curl nor nc available for readiness probe" >&2
  SUCCESS=1
fi
# Determine test_ok from test log presence
TEST_OK=false
if [ -f "$WORKSPACE/test.log" ]; then
  if ! grep -qi "FAIL" "$WORKSPACE/test.log" >/dev/null 2>&1; then TEST_OK=true; fi
fi
# Read node/npm versions if present
NODE_VER="$(cat node.version 2>/dev/null || echo unknown)"
NPM_VER="$(cat npm.version 2>/dev/null || echo unknown)"
if [ "$SUCCESS" = 0 ]; then
  jq -n --arg node "$NODE_VER" --arg npm "$NPM_VER" --argjson build true --argjson server true --argjson test $([ "$TEST_OK" = true ] && echo true || echo false) '{build_ok:$build,server_ok:$server,test_ok:$test,node_version:$node,npm_version:$npm}' > "$SUMMARY"
  echo "OK" > "$WORKSPACE/validation.result"
else
  jq -n --arg node "$NODE_VER" --arg npm "$NPM_VER" --argjson build true --argjson server false --argjson test $([ "$TEST_OK" = true ] && echo true || echo false) '{build_ok:$build,server_ok:$server,test_ok:$test,node_version:$node,npm_version:$npm}' > "$SUMMARY"
  echo "VALIDATION FAILED: server did not respond" > "$WORKSPACE/validation.result"
fi
# Cleanup: kill process group if present
if [ -f "$PGIDFILE" ]; then
  PGID=$(cat "$PGIDFILE" 2>/dev/null || true)
  if [ -n "$PGID" ]; then kill -- -"$PGID" >/dev/null 2>&1 || true; fi
fi
# ensure PID fallback
if [ -n "${PID:-}" ]; then kill "$PID" >/dev/null 2>&1 || true; fi
exit 0

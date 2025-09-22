#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/ekyc-application-125058-126435/DIGIO/NSDLeSign"
cd "$WORKSPACE"
# Build if build script present, capture output
BUILD_LOG="$WORKSPACE/build.log"
rm -f "$BUILD_LOG"
npm run build --if-present > "$BUILD_LOG" 2>&1 || (jq -n --arg e "build_failed" '{build_ok:false,error:$e}' > "$WORKSPACE/validation.summary.json"; cat "$BUILD_LOG" >&2; exit 12)
exit 0

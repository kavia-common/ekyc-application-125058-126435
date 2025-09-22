#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/ekyc-application-125058-126435/DIGIO/NSDLeSign"
cd "$WORKSPACE"
# Detect existing react dependency using node safely
if [ -f package.json ]; then
  if node -e "try{const p=require('./package.json'); process.exit(p.dependencies&&p.dependencies.react?0:1);}catch(e){process.exit(1)}" >/dev/null 2>&1; then
    exit 0
  fi
fi
# backup existing package.json
[ -f package.json ] && cp package.json "package.json.bak.$(date -u +%s)"
cat > package.json <<'JSON'
{
  "name": "nsdlesign",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "react": "18.2.0",
    "react-dom": "18.2.0",
    "react-scripts": "5.0.1"
  },
  "devDependencies": {
    "jest": "29.6.1",
    "@testing-library/react": "14.0.0",
    "serve": "14.1.2"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "jest --passWithNoTests --runInBand",
    "start:static": "serve -s build -l $PORT"
  }
}
JSON
mkdir -p public src
cat > public/index.html <<'HTML'
<!doctype html>
<html>
  <head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>NSDLeSign</title></head>
  <body><div id="root"></div></body>
</html>
HTML
cat > src/index.js <<'JS'
import React from 'react';
import { createRoot } from 'react-dom/client';
const App = () => React.createElement('div', null, 'NSDLeSign - dev');
createRoot(document.getElementById('root')).render(React.createElement(App));
JS
cat > .dockerignore <<'DOCK'
node_modules
build
.DS_Store
.git
.env
npm-debug.log
.idea
coverage
*.log
DOCK
exit 0

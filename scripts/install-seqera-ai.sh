#!/usr/bin/env bash
# Install Seqera AI CLI (https://docs.seqera.io/platform-cloud/seqera-ai/installation).
# Requires Node.js 18+ and npm.
set -euo pipefail

if ! command -v node >/dev/null 2>&1; then
  echo "install-seqera-ai: Node.js is required (18+). Install from https://nodejs.org/ or use the devcontainer." >&2
  exit 1
fi

major=$(node -p "parseInt(process.versions.node.split('.')[0], 10)")
if [[ "$major" -lt 18 ]]; then
  echo "install-seqera-ai: Node.js 18+ required; got $(node --version)" >&2
  exit 1
fi

echo "Installing Seqera CLI globally (npm install -g seqera)..."
npm install -g seqera

seqera --version
echo "Seqera CLI OK. Next: seqera login   (or set SEQERA_ACCESS_TOKEN for automation)"
echo "Optional coding-agent skill:  seqera skill install --local"
echo "Docs: docs/SEQERA_AI.md"

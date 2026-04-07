#!/usr/bin/env bash
# Run this once in a normal terminal (outside restricted sandboxes) if `git init` fails with
# "Operation not permitted" on .git/hooks.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -d .git ]]; then
  echo "Already initialized: $ROOT/.git"
  git status -sb
  exit 0
fi

git init -b main
git add -A
git status
echo ""
echo "Review the index, then:"
echo "  git commit -m \"chore: initial bwa-neo import\""
echo "  gh auth setup-git   # once per machine so git push uses gh credentials"
echo "  gh repo create bwa-neo --public --source=. --remote=origin --push"
echo "  # or: --private; if push fails but repo exists, run: git push -u origin main"
echo "  # see docs/DEVELOPMENT.md"

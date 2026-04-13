#!/usr/bin/env bash
# Publish staged GitHub Wiki Markdown from docs/wiki-wip/ using GitHub CLI
# for clone, then Git (only inside the wiki clone) for commit and push.
#
# Prefer gh everywhere GitHub exposes it:
#   - gh repo clone …     (wiki remote)
#   - gh browse --wiki …  (open browser to create the first wiki page)
#   - gh auth setup-git   (once per machine; run before git push)
#
# Git is still required for git add / commit / push in the .wiki repository;
# there is no gh subcommand for wiki commits.

set -euo pipefail

REPO_SLUG="${WIKI_REPO_SLUG:-yassineS/bwa-neo}"
WIKI_URL="https://github.com/${REPO_SLUG}.wiki.git"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAGING="${ROOT}/docs/wiki-wip"
WIKI_CLONE="${WIKI_CLONE_DIR:-${ROOT}/../bwa-neo.wiki}"

WIKI_FILES=(
  Home.md
  Usage-and-features.md
  Contributing-and-agents.md
  Build-and-test.md
  Architecture-and-scope.md
  Benchmarks-and-research.md
  Security-licence-and-conduct.md
  _Sidebar.md
  _Footer.md
)

if [[ ! -d "$STAGING" ]]; then
  echo "error: missing ${STAGING}" >&2
  exit 1
fi

for f in "${WIKI_FILES[@]}"; do
  if [[ ! -f "${STAGING}/${f}" ]]; then
    echo "error: missing staged file ${STAGING}/${f}" >&2
    exit 1
  fi
done

if [[ ! -d "${WIKI_CLONE}/.git" ]]; then
  echo "Cloning wiki into ${WIKI_CLONE} (gh repo clone) ..."
  if ! gh repo clone "${WIKI_URL}" "${WIKI_CLONE}"; then
    echo "" >&2
    echo "error: wiki clone failed (often 'Repository not found' until the wiki git exists)." >&2
    echo "Seed the wiki once from the CLI, create a short Home page in the browser, then re-run:" >&2
    echo "  gh browse --wiki ${REPO_SLUG}" >&2
    exit 1
  fi
fi

echo "Copying staged wiki pages ..."
for f in "${WIKI_FILES[@]}"; do
  cp "${STAGING}/${f}" "${WIKI_CLONE}/${f}"
done

cd "${WIKI_CLONE}"
git add "${WIKI_FILES[@]}"
if git diff --staged --quiet; then
  echo "Nothing to commit (wiki already matches staging)."
  exit 0
fi

git commit -m "docs: sync wiki pages from bwa-neo docs/wiki-wip"
git push
echo "Wiki updated. Open with: gh browse --wiki ${REPO_SLUG}"

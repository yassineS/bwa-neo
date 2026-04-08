#!/usr/bin/env bash
# Verify Seqera CLI is installed. If SEQERA_ACCESS_TOKEN or TOWER_ACCESS_TOKEN is set, checks headless auth.
set -euo pipefail

if ! command -v seqera >/dev/null 2>&1; then
  echo "check-seqera-ai FAIL: seqera not in PATH. Run: ./scripts/install-seqera-ai.sh" >&2
  exit 1
fi

seqera --version

if [[ -n "${SEQERA_ACCESS_TOKEN:-}" ]] || [[ -n "${TOWER_ACCESS_TOKEN:-}" ]]; then
  echo "Token present; probing headless..."
  if seqera ai --headless "Reply with exactly: ok" >/dev/null 2>&1; then
    echo "check-seqera-ai OK (authenticated headless)"
  else
    echo "check-seqera-ai FAIL: headless seqera ai failed; check token or run seqera login" >&2
    exit 1
  fi
else
  echo "check-seqera-ai OK (CLI only). Set SEQERA_ACCESS_TOKEN or run seqera login for full AI."
fi

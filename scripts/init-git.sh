#!/usr/bin/env bash
# Deprecated name: use scripts/bootstrap-git.sh (see docs/DEVELOPMENT.md).
exec "$(dirname "$0")/bootstrap-git.sh" "$@"

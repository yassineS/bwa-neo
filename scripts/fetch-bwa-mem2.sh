#!/usr/bin/env bash
# Download bwa-mem2 sources into third_party/bwa-mem2 (MIT license).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${ROOT}/third_party/bwa-mem2"
mkdir -p "${ROOT}/third_party"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
curl -fsSL -o src.tar.gz https://github.com/bwa-mem2/bwa-mem2/archive/refs/heads/master.tar.gz
tar xzf src.tar.gz
rm -rf "$DEST"
mv bwa-mem2-master "$DEST"
echo "Fetched bwa-mem2 into $DEST"
echo "Build with: cd $DEST && make"

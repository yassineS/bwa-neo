#!/usr/bin/env bash
# Regression: mapped read first 11 SAM fields match committed expectation (seq + qual + core fields).
# Optional tags (NM, MD, …) are ignored so minor BWA tag changes do not break the test.
set -euo pipefail
BWA="${1:?usage: golden_sam.sh /path/to/bwa}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
FIX="${ROOT}/fixtures/tiny"
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
cd "$WORKDIR"

cp "${FIX}/ref.fa" "${FIX}/reads.fq" .

"$BWA" index ref.fa 2>/dev/null
"$BWA" aln ref.fa reads.fq > reads.sai 2>/dev/null
"$BWA" samse ref.fa reads.sai reads.fq 2>/dev/null | awk '/^r1\t/{
  for(i=1;i<=11;i++){ printf "%s%s", $i, (i<11 ? "\t" : "\n") }
  exit
}' > got.first11.tsv

if ! cmp -s got.first11.tsv "${FIX}/expected.r1.first11.tsv"; then
  echo "golden_sam FAIL: first 11 fields differ" >&2
  echo "expected:" >&2
  cat "${FIX}/expected.r1.first11.tsv" >&2
  echo "got:" >&2
  cat got.first11.tsv >&2
  exit 1
fi

# Threaded samse must match single-threaded alignment line
"$BWA" samse -t 4 ref.fa reads.sai reads.fq 2>/dev/null | awk '/^r1\t/{
  for(i=1;i<=11;i++){ printf "%s%s", $i, (i<11 ? "\t" : "\n") }
  exit
}' > got.threaded.first11.tsv
if ! cmp -s got.threaded.first11.tsv "${FIX}/expected.r1.first11.tsv"; then
  echo "golden_sam FAIL: samse -t output differs from single-threaded" >&2
  exit 1
fi

echo "golden_sam OK"

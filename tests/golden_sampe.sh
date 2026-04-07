#!/usr/bin/env bash
# Regression: paired-end sampe first 11 SAM fields for both mates match fixture.
set -euo pipefail
BWA_INPUT="${1:?usage: golden_sampe.sh /path/to/bwa}"
BWA="$(cd "$(dirname "$BWA_INPUT")" && pwd)/$(basename "$BWA_INPUT")"
ROOT="$(cd "$(dirname "$0")" && pwd)"
FIX="${ROOT}/fixtures/tiny_pe"
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
cd "$WORKDIR"

cp "${FIX}/ref.fa" "${FIX}/r1.fq" "${FIX}/r2.fq" .

"$BWA" index ref.fa 2>/dev/null
"$BWA" aln ref.fa r1.fq > r1.sai 2>/dev/null
"$BWA" aln ref.fa r2.fq > r2.sai 2>/dev/null
"$BWA" sampe ref.fa r1.sai r2.sai r1.fq r2.fq 2>/dev/null | awk '/^pair\t/{
  for(i=1;i<=11;i++){ printf "%s%s", $i, (i<11 ? "\t" : "\n") }
}' > got.pair.first11.tsv

if ! cmp -s got.pair.first11.tsv "${FIX}/expected.pair.first11.tsv"; then
  echo "golden_sampe FAIL: first 11 fields differ" >&2
  exit 1
fi

# Threaded sampe must match single-threaded output (normal and edge thread values).
"$BWA" sampe -t 4 ref.fa r1.sai r2.sai r1.fq r2.fq 2>/dev/null | awk '/^pair\t/{
  for(i=1;i<=11;i++){ printf "%s%s", $i, (i<11 ? "\t" : "\n") }
}' > got.pair.threaded.first11.tsv
if ! cmp -s got.pair.threaded.first11.tsv "${FIX}/expected.pair.first11.tsv"; then
  echo "golden_sampe FAIL: sampe -t output differs from single-threaded" >&2
  exit 1
fi

"$BWA" sampe -t 0 ref.fa r1.sai r2.sai r1.fq r2.fq 2>/dev/null | awk '/^pair\t/{
  for(i=1;i<=11;i++){ printf "%s%s", $i, (i<11 ? "\t" : "\n") }
}' > got.pair.thread0.first11.tsv
if ! cmp -s got.pair.thread0.first11.tsv "${FIX}/expected.pair.first11.tsv"; then
  echo "golden_sampe FAIL: sampe -t 0 should clamp to single-thread behavior" >&2
  exit 1
fi

echo "golden_sampe OK"

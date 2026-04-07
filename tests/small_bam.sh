#!/usr/bin/env bash
# Regression: tiny bwa SAM output remains valid and stable after BAM conversion.
set -euo pipefail
BWA_INPUT="${1:?usage: small_bam.sh /path/to/bwa}"
BWA="$(cd "$(dirname "$BWA_INPUT")" && pwd)/$(basename "$BWA_INPUT")"
ROOT="$(cd "$(dirname "$0")" && pwd)"
FIX="${ROOT}/fixtures/tiny"
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
cd "$WORKDIR"

cp "${FIX}/ref.fa" "${FIX}/reads.fq" .

"$BWA" index ref.fa 2>/dev/null
"$BWA" aln ref.fa reads.fq > reads.sai 2>/dev/null
"$BWA" samse ref.fa reads.sai reads.fq 2>/dev/null > out.sam

samtools view -bS out.sam > out.bam
samtools index out.bam
samtools quickcheck out.bam
samtools view -h out.bam > roundtrip.sam

awk '/^r1\t/{
  for(i=1;i<=11;i++){ printf "%s%s", $i, (i<11 ? "\t" : "\n") }
  exit
}' roundtrip.sam > got.bam.first11.tsv

if ! cmp -s got.bam.first11.tsv "${FIX}/expected.r1.first11.tsv"; then
  echo "small_bam FAIL: BAM round-trip differs from expected first 11 fields" >&2
  echo "expected:" >&2
  cat "${FIX}/expected.r1.first11.tsv" >&2
  echo "got:" >&2
  cat got.bam.first11.tsv >&2
  exit 1
fi

echo "small_bam OK"

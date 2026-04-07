#!/usr/bin/env bash
# End-to-end smoke: index tiny ref, aln, samse. Uses bash only + bwa binary.
set -euo pipefail
BWA_INPUT="${1:?usage: smoke_align.sh /path/to/bwa}"
BWA="$(cd "$(dirname "$BWA_INPUT")" && pwd)/$(basename "$BWA_INPUT")"
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
cd "$WORKDIR"

cat > ref.fa <<'FA'
>chr1
ACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT
FA

"$BWA" index ref.fa
printf '@r1\nACGTACGTACGTACGT\n+\nIIIIIIIIIIIIIIII\n' > reads.fq
"$BWA" aln ref.fa reads.fq > reads.sai
"$BWA" samse ref.fa reads.sai reads.fq | head -5 | grep -q '^@'
"$BWA" samse -t 2 ref.fa reads.sai reads.fq | head -5 | grep -q '^@'
echo "smoke_align OK"

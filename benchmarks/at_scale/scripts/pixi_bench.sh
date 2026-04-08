#!/usr/bin/env bash
set -euo pipefail
# Usage: pixi_bench.sh <outdir_name> [--neo-only]
AT_SCALE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "${AT_SCALE}/../.." && pwd)"
OUT_NAME="${1:?outdir name}"
NEO_ONLY=false
[[ "${2:-}" == "--neo-only" ]] && NEO_ONLY=true

export NXF_HOME="${AT_SCALE}/.nextflow_home"
mkdir -p "${NXF_HOME}"
export BWA_NEO="${ROOT}/build-benchmark/bwa"
test -x "${BWA_NEO}"

OUTDIR="${AT_SCALE}/nextflow/${OUT_NAME}"

if ${NEO_ONLY}; then
  exec nextflow run "${AT_SCALE}/nextflow/main.nf" -profile standard \
    --bwa_neo "${BWA_NEO}" \
    --enable_baseline false \
    --outdir "${OUTDIR}"
else
  export BWA_BASELINE="$(command -v bwa)"
  exec nextflow run "${AT_SCALE}/nextflow/main.nf" -profile standard \
    --bwa_neo "${BWA_NEO}" \
    --enable_baseline true \
    --bwa_baseline "${BWA_BASELINE}" \
    --outdir "${OUTDIR}"
fi

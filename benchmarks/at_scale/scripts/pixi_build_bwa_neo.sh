#!/usr/bin/env bash
set -euo pipefail
# Repo root from benchmarks/at_scale/scripts/
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BUILD_DIR="${ROOT}/build-benchmark"
cmake -S "${ROOT}" -B "${BUILD_DIR}" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_TESTING=OFF \
  -DCMAKE_INSTALL_PREFIX="${BUILD_DIR}/install"
cmake --build "${BUILD_DIR}"

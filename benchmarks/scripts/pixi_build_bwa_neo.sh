#!/usr/bin/env bash
# Build bwa-neo for benchmark runs. Invoked from Pixi (PIXI_PROJECT_ROOT = benchmarks/).
set -euo pipefail

: "${PIXI_PROJECT_ROOT:?PIXI_PROJECT_ROOT is not set}"

REPO_ROOT="$(cd "${PIXI_PROJECT_ROOT}/.." && pwd)"
BUILD_DIR="${REPO_ROOT}/build-benchmark"

if [[ -f "${BUILD_DIR}/CMakeCache.txt" ]] && grep -q 'benchmarks/at_scale/' "${BUILD_DIR}/CMakeCache.txt"; then
  echo "pixi_build_bwa_neo: removing stale CMakeCache.txt (references old benchmarks/at_scale/.pixi paths)" >&2
  rm -f "${BUILD_DIR}/CMakeCache.txt"
fi

NINJA="$(command -v ninja || true)"
if [[ -z "${NINJA}" ]]; then
  echo "pixi_build_bwa_neo: ninja not found on PATH (is the pixi env activated?)" >&2
  exit 1
fi

# Prefer conda/pixi compilers when CC/CXX are set and executable; otherwise fall back.
pick_cc() {
  if [[ -n "${CC:-}" && -x "${CC}" ]]; then
    printf '%s' "${CC}"
    return
  fi
  if [[ -n "${CC:-}" ]] && command -v "${CC}" &>/dev/null; then
    command -v "${CC}"
    return
  fi
  command -v cc
}

pick_cxx() {
  if [[ -n "${CXX:-}" && -x "${CXX}" ]]; then
    printf '%s' "${CXX}"
    return
  fi
  if [[ -n "${CXX:-}" ]] && command -v "${CXX}" &>/dev/null; then
    command -v "${CXX}"
    return
  fi
  command -v c++
}

CC_BIN="$(pick_cc)"
CXX_BIN="$(pick_cxx)"
if [[ -z "${CC_BIN}" || -z "${CXX_BIN}" ]]; then
  echo "pixi_build_bwa_neo: could not resolve C/C++ compilers (CC/CXX or cc/c++)" >&2
  exit 1
fi

echo "pixi_build_bwa_neo: REPO_ROOT=${REPO_ROOT}" >&2
echo "pixi_build_bwa_neo: CMAKE_MAKE_PROGRAM=${NINJA}" >&2
echo "pixi_build_bwa_neo: CMAKE_C_COMPILER=${CC_BIN}" >&2
echo "pixi_build_bwa_neo: CMAKE_CXX_COMPILER=${CXX_BIN}" >&2

cmake -S "${REPO_ROOT}" -B "${BUILD_DIR}" -G Ninja \
  -DCMAKE_MAKE_PROGRAM="${NINJA}" \
  -DCMAKE_C_COMPILER="${CC_BIN}" \
  -DCMAKE_CXX_COMPILER="${CXX_BIN}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_TESTING=OFF

cmake --build "${BUILD_DIR}"

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Limit parallel builds by default on shared machines; override with NPROC.
NPROC="${NPROC:-4}"

PREFIX="${PREFIX:-$ROOT/local_install}"
CONC_PREFIX="${CONC_PREFIX:-$PREFIX/concurrency}"
FILT_PREFIX="${FILT_PREFIX:-$PREFIX/filter}"

reset_stale_cmake_build_dir() {
  local src_dir="$1"
  local build_dir="$2"
  local cache_file="$build_dir/CMakeCache.txt"

  if [ ! -f "$cache_file" ]; then
    return
  fi

  if ! grep -Fq "$src_dir" "$cache_file"; then
    echo "[deps] removing stale CMake build dir: $build_dir"
    rm -rf "$build_dir"
  fi
}

echo "[deps] prefix: $PREFIX"
mkdir -p "$PREFIX"

echo "[deps] build Concurrency -> $CONC_PREFIX"
reset_stale_cmake_build_dir "$ROOT/deps/concurrency" "$ROOT/build/concurrency"
mkdir -p "$ROOT/build/concurrency"
cmake -S "$ROOT/deps/concurrency" -B "$ROOT/build/concurrency" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$CONC_PREFIX"
cmake --build "$ROOT/build/concurrency" -j"$NPROC"
cmake --install "$ROOT/build/concurrency"

echo "[deps] build Filter -> $FILT_PREFIX"
reset_stale_cmake_build_dir "$ROOT/deps/filter" "$ROOT/build/filter"
mkdir -p "$ROOT/build/filter"
cmake -S "$ROOT/deps/filter" -B "$ROOT/build/filter" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$FILT_PREFIX" \
  -DCMAKE_PREFIX_PATH="$CONC_PREFIX"
cmake --build "$ROOT/build/filter" -j"$NPROC"
cmake --install "$ROOT/build/filter"

echo "[deps] done"
echo "[deps] Concurrency: $CONC_PREFIX"
echo "[deps] Filter:      $FILT_PREFIX"

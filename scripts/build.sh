#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# --disable-benchmarks: the criterion bench component must not enter the normal
# solver plan (it backtracks the whole plan and breaks `cabal test`).
exec cabal build all --disable-benchmarks

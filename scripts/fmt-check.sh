#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
fourmolu --mode check .
# -d prints the diff and exits nonzero when unformatted (diagnosable gate).
find . -name '*.cabal' -not -path './dist-newstyle/*' -exec cabal-fmt -d {} +

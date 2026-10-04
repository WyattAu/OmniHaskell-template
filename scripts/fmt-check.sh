#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
fourmolu --mode check .
# cabal-fmt: apply, then fail on drift — the CI log shows the exact diff.
find . -name '*.cabal' -not -path './dist-newstyle/*' -exec cabal-fmt -i {} +
git diff --exit-code -- '*.cabal'

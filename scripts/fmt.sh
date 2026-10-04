#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
fourmolu -i .
find . -name '*.cabal' -not -path './dist-newstyle/*' -exec cabal-fmt -i {} +

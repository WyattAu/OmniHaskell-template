#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
fourmolu --mode check .
find . -name '*.cabal' -not -path './dist-newstyle/*' -exec cabal-fmt -c {} +

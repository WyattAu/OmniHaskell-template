#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
fourmolu --mode check .
# -c = check mode (exit 1 when unformatted).
find . -name '*.cabal' -not -path './dist-newstyle/*' -exec cabal-fmt -c {} +

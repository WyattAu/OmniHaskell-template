#!/usr/bin/env bash
# Dead-code gate: requires a prior `cabal build` (hie files). The CI weeder
# job builds first, then weeds.
set -euo pipefail
cd "$(dirname "$0")/.."
exec weeder

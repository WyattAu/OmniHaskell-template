#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
exec cabal haddock all --haddock-hyperlink-source

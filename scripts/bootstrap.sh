#!/usr/bin/env bash
# Non-nix fallback instructions. Canonical env: flake.nix (GHC 9.8 + HLS).
set -euo pipefail
cat <<'MSG'
Manual toolchain (no nix):
  1. ghcup (https://www.haskell.org/ghcup/) then:
       ghcup install ghc  9.8.4
       ghcup install cabal latest
       ghcup install hls  latest
  2. cabal update && cabal build all
  3. make ci
Prefer zero setup? Open the repo in a devcontainer, or `nix develop`.
MSG

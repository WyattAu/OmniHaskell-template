#!/usr/bin/env bash
# Bootstrap ghcup + GHC 9.8 + cabal + HLS for the image-flavor devcontainer.
set -euo pipefail
if command -v ghc >/dev/null && [ "$(ghc --numeric-version | cut -d. -f1-2)" = "9.8" ]; then
  echo "GHC 9.8 already present"; exit 0
fi
bootstrap="$(mktemp -d)"
curl -sSfL https://downloads.haskell.org/~ghcup/x86_64-linux-ghcup -o "$bootstrap/ghcup"
chmod +x "$bootstrap/ghcup"
"$bootstrap/ghcup" install ghc 9.8.4 --set
"$bootstrap/ghcup" install cabal latest --set
"$bootstrap/ghcup" install hls latest --set
"$bootstrap/ghcup" set ghc 9.8.4
# Persist for future shells
mkdir -p ~/.ghcup/bin && cp "$bootstrap/ghcup" ~/.ghcup/bin/ && \
  echo 'export PATH="$HOME/.ghcup/bin:$PATH"' >> ~/.bashrc
cabal update

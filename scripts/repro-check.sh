#!/usr/bin/env bash
# Reproducible-build check (loop 3): build twice from a clean state with a pinned
# epoch and compare artifact hashes.
#
# MODE=gate - "gate" for toolchains that are deterministic (a mismatch is a
# real finding), "report" for toolchains that embed timestamps by design (a
# mismatch is printed and explained, never blocks). See the ADR.
set -euo pipefail
cd "$(dirname "$0")/.."
MODE=gate
EPOCH="${SOURCE_DATE_EPOCH:-$(git log -1 --pretty=%ct 2>/dev/null || echo 0)}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

compare() {
  if [ "$1" = "$2" ]; then
    echo "reproducible: OK ($1)"
    return 0
  fi
  echo "reproducible: MISMATCH" >&2
  echo "  run A: $1" >&2
  echo "  run B: $2" >&2
  if [ "$MODE" = "gate" ]; then
    echo "  this toolchain is expected to be deterministic - fix the build" >&2
    exit 1
  fi
  echo "  reported only: " >&2
  exit 0
}

# Measured: GHC 9.8 `.hi` files hash identically across two from-scratch builds,
# so this gates. The comment stays because the assumption used to be the opposite
# and was wrong.
fingerprint() {
  cabal build all >/dev/null
  find dist-newstyle -name '*.hi' -print0 | sort -z | xargs -0 sha256sum | awk '{print $1, $2}'
}
a="$(fingerprint)"
rm -rf dist-newstyle
b="$(fingerprint)"
compare "$a" "$b"

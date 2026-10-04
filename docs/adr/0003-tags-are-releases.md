# 0003 — Tags are releases (no central registry)

Date: 2026-10-04

## Status

Accepted

## Context

Hackage publication is optional for internal tools; Haddock serves docs.

## Decision

Releases are git tags (`v*`) with attested binaries (linux + macos) and a
CHANGELOG entry. Hackage publication is opt-in per package: add
`uploaded:` once, then `cabal upload` in the release workflow.

## Consequences

- Zero registry ceremony for internal tools; docs + binaries are the product.

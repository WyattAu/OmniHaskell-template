# 0002 — GHC baseline 9.8, compat 9.6, tip 9.10

Date: 2026-10-04

## Status

Accepted

## Context

HLS releases track specific GHC versions; packages need a stable baseline
while the ecosystem moves.

## Decision

- **9.8.4 is the baseline**: gated CI leg, the flake pin, the devcontainer.
- **9.6 is the compat leg**: proves down-version portability.
- **9.10 is the tip leg**: experimental, allowed to fail, promoted when the
  ecosystem (esp. HLS) stabilizes.

## Consequences

- Upgrading the baseline is an ADR + one flake/CI edit, never an accident.

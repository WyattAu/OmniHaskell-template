# 0002 — Estate gates and thresholds

Date: 2026-10-04

## Status

Accepted

## Context

Derived projects need CI that is maximalist but not arbitrary. The estate
already defines a tiered gate matrix (engineering-standards README) and
per-language coverage tiers.

## Decision

- This template defaults to **tier a** gates where the estate provides a
  reusable workflow for the language; otherwise the template's own
  `scripts/*.sh` implement the equivalent checks locally.
- Coverage thresholds (informational until the project sets stricter ones):
  Haskell: hpc informational start — 70% (a) / 60% (b) / 50% (c); raise per package when the domain justifies it.
- Monthly bitrot cron + one experimental allowed-fail leg on the next
  toolchain version, per the Omni Core Contract.

## Consequences

- Derived projects inherit a defensible default bar and can raise it per
  package; lowering it requires an ADR.

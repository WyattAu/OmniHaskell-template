# 0000 — Record architecture decisions

Date: 2026-10-04

## Status

Accepted

## Context

Decisions affecting layout, gates, tooling, or the Omni Core Contract must be
discoverable and dated, or every later contributor re-litigates them.

## Decision

Use lightweight ADRs in `docs/adr/`, numbered `NNNN-kebab-title.md`, with
Status / Context / Decision / Consequences sections. Append-only: supersede,
never edit history.

## Consequences

- Slightly more writing per decision.
- `git log docs/adr/` becomes the decision history of the repo.

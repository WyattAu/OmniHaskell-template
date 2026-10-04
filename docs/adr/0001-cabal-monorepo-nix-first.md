# 0001 — Cabal multi-package monorepo, nix owns GHC

Date: 2026-10-04

## Status

Accepted

## Context

Haskell toolchain churn (GHC/HLS version coupling) is the ecosystem's
biggest onboarding tax. The estate already settled the pattern in OmniR:
nix owns system dependencies, the language-native lock owns packages.

## Decision

- `cabal.project` lists `packages/*`; the repo is the unit of consistency.
- `flake.nix` provides GHC 9.8 + HLS + formatters — the pin everyone shares.
- `index-state` in cabal.project guards against partial-Hackage builds.
- Cabal (not stack, not nix builds) drives iteration: fast incremental
  `dist-newstyle`, same commands host/devcontainer/CI.

## Consequences

- nix users: `direnv allow` and everything matches CI.
- non-nix users: ghcup bootstrap documented (`scripts/bootstrap.sh`),
  devcontainers for zero setup.

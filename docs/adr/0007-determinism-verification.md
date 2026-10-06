# ADR-7: Determinism is verified, and only where it is achievable

- **Status**: Accepted (loop 3)
- **Date**: 2026-10-06

## Context

Every Omni template claims determinism somewhere (pinned lockfiles, pinned
toolchains, reproducible-build notes). Loop 2 also found the gap between the
claim and reality: `scripts/reproducible-build.sh` existed in this repo and was
named in ADR-0006, but **no make verb and no CI job ran it**. A determinism
claim with nothing behind it is documentation, not engineering.

The market's honest position: reproducibility is a property of a *toolchain*,
not of a project. Go with `-trimpath` is reproducible. Python wheels honour
`SOURCE_DATE_EPOCH`. Rust is reproducible with a pinned epoch and a clean
target. GHC writes build timestamps into interface files; `ld` embeds build
ids; `tofu plan` serialises a run id. Asking those to hash identically is
asking for something the toolchain will not give.

## Decision

**Verify reproducibility where the toolchain allows it; measure and report it
where it does not.**

1. `scripts/repro-check.sh` builds twice from a clean state with a pinned
   `SOURCE_DATE_EPOCH` and compares artifact hashes. `make repro` runs it; the
   advisory `repro` CI job runs the same command.
2. `MODE=gate` where the toolchain is deterministic (OmniRust, OmniGo, OmniPython, OmniTS, OmniDocs, OmniLean, OmniDotfiles): a mismatch is a
   real defect and fails.
3. `MODE=report` where the toolchain embeds timestamps or ids by design
   (OmniHaskell, OmniEmbedded, OmniInfra): the mismatch is printed with the reason and does not block. A
   gate that can never fail is theatre; a report that never moves is a backlog
   item with a name.
4. The epoch comes from the last commit (`git log -1 --pretty=%ct`) unless
   `SOURCE_DATE_EPOCH` is set, so a rerun on the same commit measures the same
   thing.
5. Advisory for one loop (LOOP.md graduation policy), then blocking where the
   mode is `gate`.

## Consequences

- **Good**: the determinism claim is now a job, not a sentence; a regression in
  build inputs (a timestamp leaking into an artifact, a non-pinned generator)
  fails loudly.
- **Good**: the report-mode list is a precise upgrade backlog: reproducible GHC,
  reproducible firmware, reproducible plans.
- **Cost**: two from-scratch builds per job, so the job is slow by design.
- **Cost**: reproducibility is per-architecture and per-toolchain - a green run
  on Linux says nothing about Windows or macOS artifacts. Those legs run the
  same script, which is the point.

# ADR-10: Determinism is verified, and only where it is achievable

- **Status**: Accepted (loop 3)
- **Date**: 2026-10-06

## Context

Every Omni template claims determinism somewhere (pinned lockfiles, pinned
toolchains, reproducible-build notes). Loop 2 also found the gap between the
claim and reality: `scripts/reproducible-build.sh` existed in this repo and was
named in ADR-0009, but **no make verb and no CI job ran it**. A determinism
claim with nothing behind it is documentation, not engineering.

The usual assumption is that reproducibility is a property of a *toolchain*:
Go with `-trimpath` is reproducible, GHC writes timestamps into interface
files, `ld` embeds build ids, `tofu plan` serialises a run id. On that
assumption the first version of this check shipped in `report` mode for
**Haskell, Embedded and Infra** - print the mismatch, never block.

Then we measured. All three hash **identically** across two from-scratch
builds: GHC 9.8's `.hi` files, the RP2350 firmware ELF, and `tofu plan`
binaries. The assumption was wrong, so the escape hatch is no longer used: every
template in the estate gates.

## Decision

**Verify reproducibility where the toolchain allows it; measure and report it
where it does not.**

1. `scripts/repro-check.sh` builds twice from a clean state with a pinned
   `SOURCE_DATE_EPOCH` and compares artifact hashes. `make repro` runs it; the
   advisory `repro` CI job runs the same command.
2. `MODE=gate` everywhere: a mismatch is a real defect and fails. `MODE=report`
   still exists in the script as an escape hatch for a toolchain that turns out
   to be non-deterministic, and its use requires evidence in this ADR - not a
   guess. A gate that can never fail is theatre; so is a report that never
   moves. (OmniRust, OmniGo, OmniPython, OmniTS, OmniDocs, OmniHaskell, OmniLean, OmniEmbedded, OmniInfra, OmniDotfiles measured reproducible.)
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
- **Good**: the report-mode list turned out to be empty. An assumption written
  down as "this toolchain cannot do it" was wrong in all three cases; only
  measuring settled it.
- **Cost**: two from-scratch builds per job, so the job is slow by design.
- **Cost**: reproducibility is per-architecture and per-toolchain - a green run
  on Linux says nothing about Windows or macOS artifacts. Those legs run the
  same script, which is the point.

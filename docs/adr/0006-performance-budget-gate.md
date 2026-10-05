# ADR-6: Performance budgets are committed baselines, gated on noise

- **Status**: Accepted (loop 2)
- **Date**: 2026-10-06

## Context

The market has settled on two answers for catching performance regressions in
CI. CodSpeed (Rust/Python/Node/Go/JVM) is the leading service; its own write-up
puts a **7% gate at roughly a 1% false-positive rate on GitHub-hosted
runners**. `benchmark-action` is the classic self-hosted option but needs a
writable `gh-pages` branch and defaults to a 200% threshold, which catches
nothing.

Neither fits a template estate. A template must be green the moment someone
clones it: no account, no token, no cloud project, no branch writes. A gate that
only works after someone signs up is not a gate.

The noise problem is not hypothetical either. Two **identical consecutive** runs
of the Astro build in this repo differed by 18% and 88% wall-clock. A naive
percentage gate on a shared runner is a coin flip, and a permanently red gate is
worse than no gate.

## Decision

**Ship a dependency-free budget gate that gates on statistics and exactness,
and reports what is too noisy to gate.**

1. Each template runs `scripts/bench-budget.sh`: measure, emit
   `bench/current.tsv`, compare against the committed `bench/baseline.tsv`
   with the identical `scripts/compare-bench.py`. One policy, one place to fix a
   bug, identical in all ten templates.
2. Rows are `name <TAB> value <TAB> unit [<TAB> mode] [<TAB> noise]`:
   - `noise` is the measurement's own spread (criterion std-dev,
     pytest-benchmark std-dev, the spread of five Go runs). A regression only
     fails if it exceeds the percentage budget **and** the noise band
     `z * sqrt(noise_c^2 + noise_b^2)`, z = 2.
   - `mode=gate` blocks; `mode=info` is recorded and printed, never blocks.
3. **What gates**: statistical microbenchmarks (criterion, pytest-benchmark,
   Go `ns/op`) with their own noise; exact byte counts (site bytes, flash/RAM,
   `.olean`). Budgets: 5% for exact bytes, 10% for statistical, with the noise
   band doing the real work.
4. **What is reported, not gated**: bare wall-clock on a shared runner
   (Haskell test time, `lake build`, the IaC gate, shell startup, Astro build
   time). CodSpeed's 7%-at-1% finding is why, and our own 18-88% swings are the
   receipt.
5. A missing baseline is **not** a failure: the first run records it and says so.
6. `bench/baseline.tsv` moves **only** via `make bench-update`. Running the gate
   twice can never absorb a regression.
7. New job, advisory policy: `perf` landed **advisory** (loop 2) and graduates
   to blocking after one green loop.

### What each template measures, and why

| Template | Gated | Reported | Why |
|---|---|---|---|
| OmniRust | criterion mean + std-dev | - | Library hot paths; criterion owns the statistics |
| OmniGo | mean of 5 runs + spread | - | Library hot paths |
| OmniPython | pytest-benchmark mean + std-dev | - | Library hot paths |
| OmniTS | site bytes (5%) | build ms | What users feel; a microbench of trivial components is runner noise |
| OmniDocs | site bytes (5%) | build ms | Same |
| OmniHaskell | - | test ms | Cold compile swamps the signal; a criterion bench component is the next step (loop 3) |
| OmniLean | `.olean` bytes (5%) | `lake build` ms | No runtime; `.olean` size is exact proof bulk, build time is not gateable |
| OmniEmbedded | flash + RAM bytes (5%) | - | Firmware size *is* the budget, and it is exact |
| OmniInfra | - | gate ms | No request hot path; contributor feedback time is the real cost |
| OmniDotfiles | - | shell startup ms | The latency dotfiles users feel, but only a dedicated machine gates it |

## Consequences

- **Good**: templates stay green with zero accounts; the policy is auditable in
  the repo; metrics are comparable across templates through one comparator.
- **Good**: the estate can honestly claim a *statistical* perf gate, which most
  templates cannot - they either have none or hand-wave a percentage.
- **Cost**: no cross-run history, so a slow drift is visible only after
  `bench-update`. CodSpeed's SaaS is the answer for projects that need history.
- **Cost**: four templates are report-only for now; Haskell gains a criterion
  bench component in loop 3, and Infra/Dotfiles gain exact proxies only if a
  meaningful one exists.
- **Not chosen**: `benchmark-action` (needs branch writes, 200% default).
- **Not chosen**: failing on a missing baseline (a fresh template would be red
  for a reason that is not a regression).
- **Upgrade path**: keep the TSV contract and swap the emitter for
  `@CodSpeedHQ/action`; nothing else in the estate has to change.

# AGENTS.md — instructions for AI coding agents

Project: **OmniHaskell-template** — a member of the WyattAu Omni template family.

## Non-negotiable contract

1. **Scripts are canonical.** `scripts/*` do the work; `make` wraps them;
   CI runs the same scripts. NEVER add CI-only steps.
2. **One source of truth per concern.** Version pins, lint policy, and
   formatting each live in exactly one file. Never add a parallel config.
3. **Never weaken the gates.** Coverage thresholds, lints, and policy
   checks are lowered only via an ADR (`docs/adr/`) with justification.
4. **Never commit secrets.** Placeholders in `.env.example` style only.
5. **Decisions get ADRs.** Layout, gate, or tooling changes require
   `docs/adr/NNNN-*.md` (Status/Context/Decision/Consequences).

## Stack

$2

## Commands

$3

- `make bench` (perf budget vs committed baseline) / `make bench-update`

- `make repro` (build twice, compare artifact hashes)

## Conventions

- Commits: conventional prefixes (`feat:`, `fix:`, `test:`, `docs:`, `chore:`).
- Requirements are REQ-tagged and traced in `REQUIREMENTS.md`.
- Estate-wide standards: [engineering-standards](https://github.com/WyattAu/engineering-standards)
  and [OMNI-CORE.md](https://github.com/WyattAu/engineering-standards/blob/main/OMNI-CORE.md).
- When unsure, read `ARCHITECTURE.md` — it explains *why*, this file
  explains *what*.

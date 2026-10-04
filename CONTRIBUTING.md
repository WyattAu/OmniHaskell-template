# Contributing

## The three rules

1. **Scripts are canonical.** `scripts/*` do the work; `make` wraps them;
   CI runs the scripts. If CI would do anything `make ci` does not do, fix
   one of them — never add a CI-only step.
2. **One source of truth per concern.** Version pins, lint policy, and
   formatting live in exactly one file each. No parallel configs.
3. **Decisions are recorded.** Any change to layout, gates, or tooling gets
   an ADR under `docs/adr/` (start from `0000-record-architecture-decisions.md`).

## Workflow

1. Fork/branch from `main`.
2. `direnv allow` (or enter a devcontainer) so your shell matches CI.
3. `make ci` must pass before every push. `make fmt` to autofix.
4. Update `REQUIREMENTS.md` traceability when behavior changes.
5. Conventional-commit prefixes (`feat:`, `fix:`, `test:`, `docs:`, `chore:`)
   keep the changelog greppable.

## Estate parity

This template is a member of the WyattAu Omni family. Estate-wide gates,
policies, and the Omni Core Contract live in
[engineering-standards](https://github.com/WyattAu/engineering-standards).
Changes that affect *all* templates belong there, not here.

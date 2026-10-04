# Architecture

Why this monorepo is shaped the way it is. Day-to-day commands: [README](README.md);
contribution rules: [CONTRIBUTING](CONTRIBUTING.md); the estate-wide contract:
[OMNI-CORE](https://github.com/WyattAu/engineering-standards/blob/main/OMNI-CORE.md).

## Principles

1. **One source of truth per concern.** One lockfile pins the toolchain; one
   scripts/ directory knows how to build; one CI workflow gates merges.
   Nothing important is duplicated per package.
2. **Packages are the unit of reuse; the repo is the unit of consistency.**
   Each package builds and tests independently; the workspace keeps them
   reproducible together.
3. **Everything is CLI-first.** `make` targets work identically in a terminal,
   VS Code, Neovim, and CI. IDE integrations are conveniences layered on top,
   never requirements.
4. **The pipeline is the contract.** If `make ci` passes locally, CI passes
   remotely. CI runs exactly what `make ci` runs — no special CI-only steps.

## Layout

```
OmniHaskell-template/
├── cabal.project        packages + index-state + -Werror (the consistency unit)
├── flake.nix            GHC 9.8 + HLS + formatters (the toolchain pin)
├── packages/omni-core   L0 leaf — total functions, hedgehog properties
├── packages/omni-app    executable composing on omni-core
├── fourmolu.yaml .hlint.yaml .weeder.yaml
├── scripts/  + Makefile the gates (make ci == CI)
├── docs/adr/            decision log
└── .github/ .forgejo/ .devcontainer/ .vscode/ .envrc
```

## Environments (three equal doors, one source of truth)

| Door | What it uses | When |
|---|---|---|
| nix + direnv (host) | `flake.nix` devShell | daily driver on nix-capable hosts |
| Devcontainer — image | language base image | zero-setup, works everywhere |
| Devcontainer — nix | `.devcontainer/nix/` | nix semantics inside a container |

All three resolve to the same toolchain versions because nix/flake is the
system-dependency source of truth and the language-native lockfile (checked
in) is the package source of truth.

## CI shape

- push(main) + pull_request + **monthly bitrot cron** (catches ecosystem
  drift push/PR never see).
- One **experimental allowed-fail leg** tracking the next toolchain version.
- Reusable estate gates where the language has one
  (see [engineering-standards](https://github.com/WyattAu/engineering-standards)).
- Releases: CHANGELOG + tag; per-language publisher with artifact attestation.

## Dependency graph

```
omni-app ──→ omni-core   (L0)
```

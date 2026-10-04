# OmniHaskell-template

Maximalist Haskell **monorepo** template: cabal multi-package, **nix owns
GHC** (9.8 baseline / 9.6 compat / 9.10 tip), HLS-first, fourmolu + hlint +
weeder gates, tasty + hedgehog property tests — full IDE/OS integration
(nix flake, dual devcontainers, VS Code). Part of the
[WyattAu Omni template family](https://github.com/WyattAu?tab=repositories&q=omni-).

## Start here (after "Use this template")

1. Rename: `omni-core` / `omni-app` → your packages (edit `cabal.project`).
2. Pick a door — all resolve to identical toolchains:

   | Door | Command |
   |---|---|
   | nix + direnv (host) | `direnv allow` |
   | Devcontainer (image) | VS Code → *Reopen in Container* (ghcup bootstrap, first boot downloads GHC+HLS) |
   | Devcontainer (nix)  | palette → *Rebuild in Container* → pick `.devcontainer/nix/` |

   No nix, no docker? `./scripts/bootstrap.sh` prints the manual path.
3. `make ci` — must be green before your first push.

## Make targets

| Target | Gate |
|---|---|
| `make build` | `cabal build all` |
| `make test` | `cabal test all` (tasty + hedgehog properties) |
| `make lint` | hlint |
| `make fmt` / `fmt-check` | fourmolu + cabal-fmt |
| `make weeder` | dead-code detection over hie files |
| `make docs` | haddock, hyperlinked source |
| `make contract` | Omni Core Contract structural checks |
| `make ci` | contract + fmt-check + lint + build + test |

CI adds the GHC matrix (9.6/9.8/9.10-tip-experimental), a weeder job, and
both devcontainer builds. `-Werror` is CI policy via `cabal.project`.

## What is inside

```
cabal.project          package list + index-state + -Werror policy
packages/omni-core     L0 leaf: total functions (safeHead/clamp), hedgehog properties
packages/omni-app      example executable composing on omni-core
fourmolu.yaml .hlint.yaml .weeder.yaml
scripts/  + Makefile   the gates (make ci == CI)
docs/adr/              decision log (nix-first, GHC baseline, tags-are-releases)
.github/workflows/     ci (GHC matrix + style + weeder), release, docs, devcontainers
.forgejo/              thin self-hosted mirror (scripts are canonical)
```

## Release flow

Tags are releases (ADR-0003): `v*` → attested binaries for linux + macos +
CHANGELOG entry. Hackage publication is opt-in per package.

## Estate pointers

- Gates, policies: [engineering-standards](https://github.com/WyattAu/engineering-standards)
- Omni Core Contract: [OMNI-CORE.md](https://github.com/WyattAu/engineering-standards/blob/main/OMNI-CORE.md)

## License

Apache-2.0 — commercial use expressly permitted.

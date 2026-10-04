# Requirements — OmniHaskell-template

Numbered, testable requirements. Every requirement maps to at least one named
test/script check; every security-relevant check cites at least one
requirement. Doc comments on the implementing item carry `REQ-NNN` tags.

## Template (toolchain) requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| REQ-T-001 | `make ci` runs the same scripts CI runs; no CI-only steps | MUST |
| REQ-T-002 | Fresh clone → green `make ci` inside the devcontainer with zero manual steps | MUST |
| REQ-T-003 | Both devcontainer flavors (image, nix) build and reach green CI | MUST |
| REQ-T-004 | Monorepo layout demonstrates one internal dependency between packages | MUST |

## Security

| ID | Requirement | Priority |
|----|-------------|----------|
| REQ-T-100 | No secrets in the scaffold; `.env.example` pattern only | MUST |
| REQ-T-101 | CI workflows run with least-privilege `permissions:` blocks | MUST |

## Traceability Matrix

| Requirement | Check (script, test) | Property class |
|-------------|----------------------|----------------|
| REQ-T-001 | `make ci` == `.github/workflows/ci.yml` step list | structural |
| REQ-T-002 | devcontainer postCreate + `make ci` in CI devcontainer job | integration |

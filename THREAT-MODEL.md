# Threat Model — OmniHaskell-template

Reference: STRIDE. Scope: the template as consumed by a derived project —
files, scripts, and CI definitions a user inherits on "Use this template".
Trust boundaries: (1) files executed by `make`/scripts on a developer host,
(2) CI workflows executing with repo-scoped tokens, (3) the dependency and
action surface pinned in manifests.

## Assets

| ID | Asset | Example |
|----|-------|---------|
| A1 | Developer host executing scaffold scripts | arbitrary code via `make` |
| A2 | CI secrets available to workflows | GITHUB_TOKEN scope, publish tokens |
| A3 | Derived projects' supply chain | lockfiles, action pins |

## STRIDE Analysis

| # | Threat | Category | Surface | Mitigation | Verifying check |
|---|--------|----------|---------|------------|-----------------|
| T1 | Malicious/typo-squatted action pinned in workflows | Elevation | `.github/workflows/*` | Pin actions by tag + dependabot weekly; document review | dependabot.yml present |
| T2 | Secret leakage through example env files | Info disclosure | `.env.example` | Examples carry placeholder values only; gitleaks hook | pre-commit config |
| T3 | Workflow injection via untrusted input in `run:` blocks | Elevation | CI | No interpolated PR titles/branch names in shell; scripted steps only | review checklist |
| T4 | Drift between local and CI gates (false confidence) | Repudiation | Makefile vs ci.yml | Contract REQ-T-001: CI mirrors `make ci` | `scripts/check-contract.sh` |
| T5 | Over-privileged GITHUB_TOKEN in derived repos | Elevation | workflows | Explicit `permissions:` blocks on every workflow | grep gate in scripts/check-contract.sh |

## Out of Scope

- Vulnerabilities in the language toolchain itself (upstream projects)
- Projects' application-level threats once derived (add your own
  THREAT-MODEL entries when your code parses untrusted input)

## Residual Risks

- Reusable workflows are consumed `@main` (estate standard); a compromised
  standards repo propagates. Mitigation: engineering-standards is
  single-owner + branch-protected.

# Thin wrapper over scripts/ — the same verbs in every Omni template.
.PHONY: bench bench-update repro build test lint fmt fmt-check weeder docs contract ci clean

build:
	./scripts/build.sh

test:
	./scripts/test.sh

lint:
	./scripts/lint.sh

fmt:
	./scripts/fmt.sh

fmt-check:
	./scripts/fmt-check.sh

weeder:
	./scripts/weeder.sh

docs:
	./scripts/docs.sh

contract:
	./scripts/check-contract.sh

## What CI gates before merge (mirror of .github/workflows/ci.yml):
ci: contract fmt-check lint build test

repro:
	./scripts/repro-check.sh

bench:
	./scripts/bench-budget.sh

bench-update:
	./scripts/bench-budget.sh --update

clean:
	cabal clean
	rm -rf dist-newstyle .hpc

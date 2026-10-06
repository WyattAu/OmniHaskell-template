#!/usr/bin/env bash
# Perf budget gate: measure, emit bench/current.tsv, compare to the committed
# baseline with the shared comparator. `make bench-update` re-baselines
# deliberately - it is the only way a baseline moves.
set -euo pipefail
cd "$(dirname "$0")/.."
BASELINE=bench/baseline.tsv
CURRENT=bench/current.tsv
THRESHOLD_PCT="${OMNI_BENCH_THRESHOLD_PCT:-10}"
UPDATE=()
[ "${1:-}" = "--update" ] && UPDATE=(--update)
mkdir -p bench

# Criterion owns the statistics; we own the policy. The benchmark component is
# kept out of the normal solver plan (see --disable-benchmarks in build.sh).
# `--time-limit` keeps the gate short.
cabal bench omni-core-bench --benchmark-options="--json $PWD/bench/criterion.json --time-limit 0.5"

# criterion's JSON layout has changed between releases, so walk the tree for
# entries that carry a mean instead of hard-coding a path.
python3 - <<'PYEMIT' >"$CURRENT"
import json
import pathlib
import sys

path = pathlib.Path("bench/criterion.json")
if not path.exists():
    sys.exit(f"bench: criterion wrote no JSON at {path}")
data = json.loads(path.read_text())

MEAN_KEYS = ("mean", "meanEstimate", "estimate", "est")
NAME_KEYS = ("name", "reportName", "benchmarkName", "id", "fullName")


def mean_of(node):
    """criterion reports seconds; nested dicts carry point_estimate/estimate."""
    for key in MEAN_KEYS:
        if key in node:
            value = node[key]
            if isinstance(value, dict):
                for inner in ("point_estimate", "estimate", "centred", "mean"):
                    if inner in value:
                        return float(value[inner])
                continue
            try:
                return float(value)
            except (TypeError, ValueError):
                continue
    return None


def name_of(node, fallback):
    for key in NAME_KEYS:
        value = node.get(key)
        if isinstance(value, str) and value:
            return value
    return fallback


def walk(node, trail="report"):
    if isinstance(node, dict):
        mean = mean_of(node)
        if mean is not None:
            yield name_of(node, trail), mean, node
            return
        for key, value in node.items():
            yield from walk(value, f"{trail}/{key}")
    elif isinstance(node, list):
        for index, value in enumerate(node):
            yield from walk(value, f"{trail}[{index}]")


def std_dev_of(node):
    for key in ("stdDev", "std_dev", "stddev"):
        value = node.get(key)
        if isinstance(value, dict):
            value = value.get("point_estimate")
        if isinstance(value, (int, float)):
            return float(value)
    return 0.0


rows = {}
for name, seconds, node in walk(data):
    rows[name] = (seconds * 1e9, std_dev_of(node) * 1e9)

if not rows:
    shape = list(data)[:8] if isinstance(data, dict) else [list(e)[:8] for e in data[:2]]
    sys.exit(f"bench: could not parse criterion JSON; top-level shape: {shape}")

for name, (value, noise) in sorted(rows.items()):
    print(f"{name}\t{value:.3f}\tns\tgate\t{noise:.3f}")
PYEMIT

python3 scripts/compare-bench.py "$BASELINE" "$CURRENT" \
  --threshold-pct "$THRESHOLD_PCT" "${UPDATE[@]+"${UPDATE[@]}"}"

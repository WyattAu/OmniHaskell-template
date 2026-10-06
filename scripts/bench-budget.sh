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

# Criterion owns the statistics; we own the policy (loop 4: the Haskell
# template finally has a real microbenchmark instead of only a wall-clock
# report). `--json` is criterion's machine output; `--time-limit` keeps the gate
# short.
OUT="$PWD/bench/criterion.json"
mkdir -p bench
cabal bench omni-core-bench --benchmark-options="--json $OUT --time-limit 0.5"

python3 - <<'PYEMIT' >"$CURRENT"
import json
import pathlib
import sys

path = pathlib.Path("bench/criterion.json")
if not path.exists():
    sys.exit(f"bench: criterion wrote no JSON at {path}")
data = json.loads(path.read_text())

# criterion's JSON is a list of report entries; tolerate a dict-of-entries too.
entries = data if isinstance(data, list) else [dict(v, name=k) for k, v in data.items()]
rows = []
for entry in entries:
    name = entry.get("name") or entry.get("reportName") or entry.get("id")
    if not name:
        continue
    # criterion reports seconds; the gate works in nanoseconds.
    mean = entry.get("mean") or entry.get("meanEstimate")
    if mean is None:
        continue
    std_dev = entry.get("stdDev") or entry.get("std_dev") or 0.0
    rows.append((name, float(mean) * 1e9, "ns", "gate", float(std_dev) * 1e9))
if not rows:
    sys.exit("bench: could not parse criterion JSON; first keys: " + str(list(data[0].keys())[:12]))
for name, value, unit, mode, noise in sorted(rows):
    print(f"{name}\t{value:.3f}\t{unit}\t{mode}\t{noise:.3f}")
PYEMIT

python3 scripts/compare-bench.py "$BASELINE" "$CURRENT" \
  --threshold-pct "$THRESHOLD_PCT" "${UPDATE[@]+"${UPDATE[@]}"}"

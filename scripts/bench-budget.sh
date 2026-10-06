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
# kept out of the normal solver plan (see --disable-benchmarks in build.sh), and
# the report file is written by the benchmark itself (jsonFile in bench/Main.hs)
# so nothing depends on criterion's CLI flags.
find . -name criterion.json -type f -delete 2>/dev/null || true
cabal bench omni-core-bench

REPORT="$(find . -name criterion.json -type f | head -1)"
[ -n "$REPORT" ] || {
  echo "bench: criterion wrote no report (looked for criterion.json)" >&2
  exit 1
}

# criterion's JSON layout has changed between releases, so walk the tree for
# entries that carry a mean instead of hard-coding a path.
python3 scripts/emit-criterion-bench.py "$REPORT" >"$CURRENT"

python3 scripts/compare-bench.py "$BASELINE" "$CURRENT" \
  --threshold-pct "$THRESHOLD_PCT" "${UPDATE[@]+"${UPDATE[@]}"}"

#!/usr/bin/env python3
"""Turn criterion's JSON report into the estate's benchmark TSV.

criterion's report layout has moved between releases, and two shapes are in the
wild:

* older: entries carrying `mean` / `stdDev` directly, sometimes nested one level
  as `{point_estimate: ...}`;
* 1.6.x: `["criterion", "<version>", [ {reportName, reportAnalysis: {anMean:
  {estPoint, estError}}, ...} ]]`.

So instead of hard-coding a path, this walks the tree, understands both shapes,
and inherits the report name down into the analysis. Values are converted from
criterion's seconds to nanoseconds, the unit the shared comparator works in.

Rows are `name<TAB>value<TAB>ns<TAB>gate<TAB>noise`, where noise is criterion's
standard deviation - that is what lets the comparator run its z-test instead of a
naive percentage comparison.
"""

from __future__ import annotations

import json
import pathlib
import sys

MEAN_KEYS = ("anMean", "mean", "meanEstimate", "estimate", "est")
STDDEV_KEYS = ("anStdDev", "stdDev", "std_dev", "stddev")
NAME_KEYS = ("reportName", "name", "benchmarkName", "id", "fullName")
POINT_KEYS = ("estPoint", "point_estimate", "estimate", "centred", "mean")
ANALYSIS_CONTAINERS = ("reportAnalysis", "analysis", "report")


def estimate(node: dict, keys: tuple[str, ...]) -> float | None:
    """Read a number, descending through criterion's Estimate wrappers."""
    for key in keys:
        if key not in node:
            continue
        value = node[key]
        if isinstance(value, dict):
            for inner in POINT_KEYS:
                inner_value = value.get(inner)
                if isinstance(inner_value, (int, float)):
                    return float(inner_value)
            continue
        if isinstance(value, (int, float)):
            return float(value)
    return None


def name_of(node: dict, fallback: str) -> str:
    for key in NAME_KEYS:
        value = node.get(key)
        if isinstance(value, str) and value:
            return value
    return fallback


def walk(node, trail: str = "report", inherited: str | None = None):
    """Yield (name, seconds, stddev) for every mean-bearing entry."""
    if isinstance(node, dict):
        name = name_of(node, inherited or trail)
        mean = estimate(node, MEAN_KEYS)
        if mean is not None:
            yield name, mean, estimate(node, STDDEV_KEYS) or 0.0
            return
        for container in ANALYSIS_CONTAINERS:
            child = node.get(container)
            if isinstance(child, dict):
                mean = estimate(child, MEAN_KEYS)
                if mean is not None:
                    yield name, mean, estimate(child, STDDEV_KEYS) or 0.0
                    return
        for key, value in node.items():
            yield from walk(value, f"{trail}/{key}", inherited=name)
    elif isinstance(node, list):
        for index, value in enumerate(node):
            yield from walk(value, f"{trail}[{index}]", inherited)


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: emit-criterion-bench.py <report.json>", file=sys.stderr)
        return 2
    report = pathlib.Path(argv[1])
    data = json.loads(report.read_text())

    rows: dict[str, tuple[float, float]] = {}
    for name, seconds, stddev in walk(data):
        rows[name] = (seconds * 1e9, stddev * 1e9)

    if not rows:
        raw = report.read_text()[:400]
        print(
            f"emit-criterion-bench: no measurements in {report}\n"
            f"  first bytes: {raw!r}",
            file=sys.stderr,
        )
        return 1

    for name, (value, noise) in sorted(rows.items()):
        print(f"{name}\t{value:.3f}\tns\tgate\t{noise:.3f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

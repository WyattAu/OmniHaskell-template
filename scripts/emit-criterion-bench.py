#!/usr/bin/env python3
"""Turn criterion's JSON report into the estate's benchmark TSV.

criterion's report layout has changed between releases (and the shape depends on
whether the report is the analysis file or the summary), so instead of hard-coding
a path this walks the tree and picks up every node that carries a mean. Values
are converted from criterion's seconds to nanoseconds, which is the unit the
shared comparator works in.

Rows are `name<TAB>value<TAB>ns<TAB>gate<TAB>noise`; the noise column is
criterion's standard deviation, which lets the comparator run its z-test instead
of a naive percentage.
"""

from __future__ import annotations

import json
import pathlib
import sys

MEAN_KEYS = ("mean", "meanEstimate", "estimate", "est")
NAME_KEYS = ("name", "reportName", "benchmarkName", "id", "fullName")
STDDEV_KEYS = ("stdDev", "std_dev", "stddev")


def scalar(node: dict, keys: tuple[str, ...]) -> float | None:
    """Read a numeric field, descending one level when criterion nests it."""
    for key in keys:
        if key not in node:
            continue
        value = node[key]
        if isinstance(value, dict):
            for inner in ("point_estimate", "estimate", "centred", "mean"):
                if inner in value and isinstance(value[inner], (int, float)):
                    return float(value[inner])
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


def walk(node, trail: str = "report"):
    """Yield (name, seconds, node) for every mean-bearing entry."""
    if isinstance(node, dict):
        mean = scalar(node, MEAN_KEYS)
        if mean is not None:
            yield name_of(node, trail), mean, node
            return
        for key, value in node.items():
            yield from walk(value, f"{trail}/{key}")
    elif isinstance(node, list):
        for index, value in enumerate(node):
            yield from walk(value, f"{trail}[{index}]")


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: emit-criterion-bench.py <report.json>", file=sys.stderr)
        return 2
    report = pathlib.Path(argv[1])
    data = json.loads(report.read_text())

    rows: dict[str, tuple[float, float]] = {}
    for name, seconds, node in walk(data):
        stddev = scalar(node, STDDEV_KEYS) or 0.0
        rows[name] = (seconds * 1e9, stddev * 1e9)

    if not rows:
        shape = (
            list(data)[:8]
            if isinstance(data, dict)
            else [list(entry)[:8] for entry in data[:2]]
            if isinstance(data, list)
            else type(data).__name__
        )
        raw = report.read_text()[:400]
        print(
            f"emit-criterion-bench: no measurements in {report}\n"
            f"  shape: {shape}\n"
            f"  first bytes: {raw!r}",
            file=sys.stderr,
        )
        return 1

    for name, (value, noise) in sorted(rows.items()):
        print(f"{name}\t{value:.3f}\tns\tgate\t{noise:.3f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

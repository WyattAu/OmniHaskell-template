#!/usr/bin/env python3
"""Compare a benchmark run against the committed baseline.

One policy for every language in the estate: a benchmark run emits TSV rows of
    name <TAB> value <TAB> unit [<TAB> mode] [<TAB> noise]
and this script compares them to the committed baseline.

The design decisions that matter:

* **Statistical rows gate statistically.** When a measurement reports its own
  noise (criterion's std-dev, pytest-benchmark's std-dev, a Go sample spread),
  a regression only fails if it exceeds both the percentage budget *and* the
  noise band: `current - baseline > z * sqrt(noise_c^2 + noise_b^2)`. Shared
  runners drift; a naive `+10% fails` is a coin flip, a z-test is not.
* **Deterministic rows gate exactly.** Bundle bytes, firmware bytes, `.olean`
  bytes have no noise, so a 5% budget is meaningful and tight.
* **Wall-clock rows on shared runners are reported, not gated** (`mode=info`).
  CodSpeed's own write-up puts a 7% gate at a ~1% false-positive rate on
  GitHub-hosted runners; our own two identical consecutive runs of the Astro
  build differed by 18% and 88%. Reporting beats a permanently red gate.
* Higher is worse for every unit we emit (`ns`, `ms`, `bytes`), so the policy
  has one direction and cannot be misread.
* A missing baseline records this run instead of failing: a fresh template is
  never red on a first perf run, and the gate is real from the second on.
* `--update` re-baselines deliberately (`make bench-update`); running the gate
  twice can never absorb a regression.
"""

from __future__ import annotations

import argparse
import math
import pathlib
import sys

Row = tuple[str, float, str, str, float]
DEFAULT_THRESHOLD_PCT = 10.0
DEFAULT_NOISE_Z = 2.0

HEADER = (
    "Committed performance baseline. Regenerate deliberately with "
    "`make bench-update`; never hand-edited."
)


def read_rows(path: pathlib.Path) -> list[Row]:
    rows: list[Row] = []
    for lineno, raw in enumerate(path.read_text().splitlines(), start=1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) < 3 or len(parts) > 5:
            raise SystemExit(
                f"{path}:{lineno}: expected name<TAB>value<TAB>unit[<TAB>mode[<TAB>noise]], "
                f"got {line!r}"
            )
        name, value, unit = parts[0], parts[1], parts[2]
        mode = parts[3] if len(parts) > 3 else "gate"
        noise = parts[4] if len(parts) > 4 else "0"
        if mode not in ("gate", "info"):
            raise SystemExit(f"{path}:{lineno}: mode must be gate or info, got {mode!r}")
        try:
            rows.append((name, float(value), unit, mode, float(noise)))
        except ValueError:
            raise SystemExit(f"{path}:{lineno}: value/noise must be numeric: {line!r}") from None
    return rows


def write_rows(path: pathlib.Path, rows: list[Row]) -> None:
    lines = [f"# {HEADER}"]
    for name, value, unit, mode, noise in sorted(rows):
        row = f"{name}\t{value:.3f}\t{unit}\t{mode}"
        if noise:
            row += f"\t{noise:.3f}"
        lines.append(row)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("baseline", type=pathlib.Path)
    ap.add_argument("current", type=pathlib.Path)
    ap.add_argument("--threshold-pct", type=float, default=DEFAULT_THRESHOLD_PCT)
    ap.add_argument("--noise-z", type=float, default=DEFAULT_NOISE_Z)
    ap.add_argument("--update", action="store_true")
    ap.add_argument("--require-baseline", action="store_true")
    args = ap.parse_args()

    if not args.current.exists():
        print(f"compare-bench: no current results at {args.current}", file=sys.stderr)
        return 1
    current = read_rows(args.current)
    if not current:
        print(f"compare-bench: {args.current} has no measurements", file=sys.stderr)
        return 1

    if args.update:
        write_rows(args.baseline, current)
        print(f"compare-bench: baseline updated from this run ({len(current)} measurements)")
        return 0

    if not args.baseline.exists() or not read_rows(args.baseline):
        if args.require_baseline:
            print("compare-bench: baseline missing and --require-baseline was set", file=sys.stderr)
            return 1
        write_rows(args.baseline, current)
        print(
            f"compare-bench: no baseline yet - recorded this run as the baseline "
            f"({len(current)} measurements). The next run is gated."
        )
        return 0

    baseline = {
        name: (value, unit, mode, noise)
        for name, value, unit, mode, noise in read_rows(args.baseline)
    }
    regressions: list[str] = []
    reported: list[str] = []
    added: list[str] = []
    removed: list[str] = []

    def line(name: str, base_value: float, value: float, note: str = "") -> str:
        delta_pct = (value - base_value) / base_value * 100.0 if base_value else float("nan")
        suffix = f"  {note}" if note else ""
        return f"  {name}: {base_value:.3f} -> {value:.3f} ({delta_pct:+.2f}%){suffix}"

    for name, value, unit, mode, noise in sorted(current):
        if name not in baseline:
            added.append(name)
            continue
        base_value, base_unit, _, base_noise = baseline[name]
        if base_unit != unit:
            print(
                f"compare-bench: {name} changed unit ({base_unit} -> {unit}); "
                "re-baseline with `make bench-update`",
                file=sys.stderr,
            )
            return 1
        if base_value <= 0:
            added.append(name)
            continue

        delta_pct = (value - base_value) / base_value * 100.0
        # noise band: only meaningful when both sides report a spread
        band = args.noise_z * math.sqrt(noise**2 + base_noise**2) if (noise or base_noise) else 0.0
        significant = band <= 0 or (value - base_value) > band

        if mode == "gate" and delta_pct > args.threshold_pct and significant:
            regressions.append(
                line(name, base_value, value, f"[noise band +/-{band:.3f} {unit}]" if band else "")
            )
        elif delta_pct < -args.threshold_pct:
            reported.append(line(name, base_value, value, "[improved]"))
        elif mode == "info":
            reported.append(line(name, base_value, value, "[reported, not gated]"))

    current_names = {name for name, _, _, _, _ in current}
    for name in baseline:
        if name not in current_names:
            removed.append(name)

    for text in reported:
        print(f"compare-bench: {text}")
    for name in added:
        print(f"compare-bench: new measurement (not compared): {name}")
    for name in removed:
        print(f"compare-bench: measurement disappeared (baseline keeps it): {name}")

    if regressions:
        print(
            f"compare-bench: {len(regressions)} regression(s) over the "
            f"{args.threshold_pct:g}% budget:",
            file=sys.stderr,
        )
        for text in regressions:
            print(text, file=sys.stderr)
        print(
            "If the regression is intended, re-baseline deliberately with `make bench-update`.",
            file=sys.stderr,
        )
        return 1

    gated = sum(1 for row in current if row[3] == "gate")
    print(
        f"compare-bench: OK - {gated} gated / {len(current) - gated} reported measurement(s) "
        f"within {args.threshold_pct:g}%"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

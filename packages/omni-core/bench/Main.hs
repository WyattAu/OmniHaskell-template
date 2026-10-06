-- | Criterion benchmarks: the perf gate's input.
--
-- @make bench@ runs this through @scripts/bench-budget.sh@, which compares the
-- measurements against the committed baseline in @bench/baseline.tsv@ using the
-- estate's shared comparator (mean + sample spread, gated with a noise band).
--
-- Each benchmark batches a thousand or ten thousand iterations: a single
-- nanosecond-scale call is dominated by timer and loop overhead, so the
-- measurements would not be comparable run to run. @whnfIO@ forces the result,
-- so nothing here can be optimised away.
module Main (main) where

import Criterion.Main (bench, bgroup, whnfIO)
import Data.Maybe (mapMaybe)
import Omni.Core (clamp, safeHead)

-- | REQ-002 on the hot path: a thousand clamps in one measurement.
clampBatch :: Int
clampBatch = sum (map (clamp 0 100) [1 .. 10_000])

-- | REQ-001 on the hot path: a thousand total head calls, counted via @mapMaybe@
-- (no partial functions anywhere, including in the benchmark).
consBatch :: Int
consBatch = length (mapMaybe (safeHead . (: [])) [1 .. 1000])

main :: IO ()
main =
  bgroup
    "omni-core"
    [ bench "clamp/batch10k" (whnfIO (pure clampBatch))
    , bench "safeHead/cons1000" (whnfIO (pure consBatch))
    ]

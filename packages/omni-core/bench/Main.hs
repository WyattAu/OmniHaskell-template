-- | Criterion benchmarks: the perf gate's input.
--
-- @make bench@ runs this through @scripts/bench-budget.sh@, which compares the
-- measurements against the committed baseline in @bench/baseline.tsv@ using the
-- estate's shared comparator (mean + sample spread, gated with a noise band).
--
-- Two details matter for the numbers to mean anything:
--
-- * The work happens /inside/ the measured action. A top-level CAF that is only
--   returned reported ~4ns for a batch of 1,000 clamps; @evaluate@ forces the
--   batch to be recomputed on every iteration.
-- * The batch is big enough that timer and loop overhead do not dominate.
module Main (main) where

import Control.Exception (evaluate)
import Criterion.Main (bench, bgroup, defaultMain, whnfIO)
import Data.Maybe (mapMaybe)
import Omni.Core (clamp, safeHead)

-- | REQ-002 on the hot path: clamp the whole batch per iteration.
clampBatch :: [Int] -> Int
clampBatch = sum . map (clamp 0 100)

-- | REQ-001 on the hot path: total head over the whole batch. @mapMaybe@ keeps
-- this partial-free, benchmark included.
consBatch :: [Int] -> Int
consBatch xs = length (mapMaybe (safeHead . (: [])) xs)

main :: IO ()
main =
  defaultMain
    [ bgroup
        "omni-core"
        [ bench "clamp/batch1k" (whnfIO (evaluate (clampBatch [1 .. 1024 :: Int])))
        , bench "safeHead/cons1k" (whnfIO (evaluate (consBatch [1 .. 1024 :: Int])))
        ]
    ]

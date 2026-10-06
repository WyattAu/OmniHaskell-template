-- | Criterion benchmarks: the perf gate's input.
--
-- @make bench@ runs this through @scripts/bench-budget.sh@, which compares the
-- measurements against the committed baseline in @bench/baseline.tsv@ using the
-- estate's shared comparator (mean + sample spread, gated with a noise band).
--
-- Two details matter for the numbers to mean anything:
--
-- * The work happens /inside/ the measured action. A @where@-bound CAF computed
--   once and merely returned reported ~4ns for a batch of 10,000 clamps.
-- * @nfIO@ takes a function plus a list of inputs and cycles through them, so
--   every iteration recomputes with a different argument and nothing can be
--   hoisted into a shared thunk.
module Main (main) where

import Control.Exception (evaluate)
import Criterion.Main (bench, bgroup, defaultMain, nfIO)
import Data.Maybe (mapMaybe)
import Omni.Core (clamp, safeHead)

-- | REQ-002 on the hot path: clamp @n@ values per iteration.
clampBatch :: Int -> Int
clampBatch n = sum (map (clamp 0 100) [1 .. n])

-- | REQ-001 on the hot path: total head over @n@ values. @mapMaybe@ keeps this
-- partial-free, benchmark included.
consBatch :: Int -> Int
consBatch n = length (mapMaybe (safeHead . (: [])) [1 .. n :: Int])

main :: IO ()
main =
  defaultMain
    [ bgroup
        "omni-core"
        [ bench "clamp/batch1k" (nfIO (evaluate . clampBatch) [1 .. 1024])
        , bench "safeHead/cons1k" (nfIO (evaluate . consBatch) [1 .. 1024])
        ]
    ]

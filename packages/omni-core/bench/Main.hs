-- | Criterion benchmarks: the perf gate's input.
--
-- @make bench@ runs this through @scripts/bench-budget.sh@, which compares the
-- measurements against the committed baseline in @bench/baseline.tsv@ using the
-- estate's shared comparator (mean + sample spread, gated with a noise band).
--
-- Three details matter for the numbers to mean anything:
--
-- * The work happens /inside/ the measured action. A @where@-bound CAF computed
--   once and merely returned reported ~4ns for a batch of 10,000 clamps.
-- * @nfIO@ takes the whole input list (@[a] -> IO b@) and cycles it internally,
--   so every iteration gets a fresh list and nothing can be hoisted into a
--   shared thunk.
-- * @mapMaybe@ instead of a partial combinator, because @-Werror@ and the
--   estate's total-function policy apply to benchmarks too.
module Main (main) where

import Control.Exception (evaluate)
import Criterion.Main (bench, bgroup, defaultMain, nfIO)
import Data.Maybe (mapMaybe)
import Omni.Core (clamp, safeHead)

-- | REQ-002 on the hot path: clamp the whole batch per iteration.
clampBatch :: [Int] -> Int
clampBatch = sum . map (clamp 0 100)

-- | REQ-001 on the hot path: total head over the whole batch.
consBatch :: [Int] -> Int
consBatch xs = length (mapMaybe (safeHead . (: [])) xs)

main :: IO ()
main =
  defaultMain
    [ bgroup
        "omni-core"
        [ bench "clamp/batch" (nfIO (evaluate . clampBatch))
        , bench "safeHead/cons" (nfIO (evaluate . consBatch))
        ]
    ]

-- | Criterion benchmarks: the perf gate's input.
--
-- @make bench@ runs this through @scripts/bench-budget.sh@, which compares the
-- measurements against the committed baseline in @bench/baseline.tsv@ using the
-- estate's shared comparator (mean + sample spread, gated with a noise band).
--
-- Two details matter for the numbers to mean anything:
--
-- * @nf@ applies the argument to the function on /every/ iteration (criterion's
--   documented workaround for GHC floating a constant argument into a CAF). An
--   earlier version returned a pre-computed top-level value and cheerfully
--   reported ~4ns for a batch of a thousand clamps.
-- * The batch is large enough that timer and loop overhead do not dominate, and
--   the work stays total (@mapMaybe@, no partial combinators) because the
--   estate's policy applies to benchmarks too.
module Main (main) where

import Criterion.Main (bench, bgroup, defaultConfig, defaultMainWith, nf)
import Criterion.Types (Verbosity (Normal), jsonFile, timeLimit, verbosity)
import Data.Maybe (mapMaybe)
import Omni.Core (clamp, safeHead)

-- | REQ-002 on the hot path: clamp the whole batch.
clampBatch :: [Int] -> Int
clampBatch = sum . map (clamp 0 100)

-- | REQ-001 on the hot path: total head over the whole batch.
consBatch :: [Int] -> Int
consBatch xs = length (mapMaybe (safeHead . (: [])) xs)

main :: IO ()
main =
  defaultMainWith
    defaultConfig
      { -- The report path is relative to whichever directory cabal runs the
        -- benchmark from, so scripts/bench-budget.sh discovers the file rather
        -- than assuming a location.
        jsonFile = Just "criterion.json"
      , timeLimit = 0.5
      , verbosity = Normal
      }
    [ bgroup
        "omni-core"
        [ bench "clamp/batch1k" (nf clampBatch [1 .. 1024 :: Int])
        , bench "safeHead/cons1k" (nf consBatch [1 .. 1024 :: Int])
        ]
    ]

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
import Data.List (foldl')
import Omni.Core (clamp, safeHead)

main :: IO ()
main =
  bgroup
    "omni-core"
    [ bench "clamp/batch10k" $
        whnfIO (pure (sum (map (clamp 0 100) [1 .. 10_000 :: Int])))
    , bench "safeHead/cons1000" $
        whnfIO
          ( pure
              ( length
                  ( foldl'
                      (\acc x -> maybe acc (: acc) (safeHead [x]))
                      []
                      [1 .. 1000 :: Int]
                  )
              )
          )
    ]

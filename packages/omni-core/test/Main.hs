module Main (main) where

import Hedgehog (Property, assert, forAll, property, (===))
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Omni.Core (clamp, safeHead)
import Test.Tasty (TestTree, defaultMain, testGroup)
import Test.Tasty.Hedgehog (testProperty)

genInts :: Hedgehog.Gen [Int]
genInts = Gen.list (Range.linear 0 100) Gen.int

-- | REQ-001: safeHead agrees with head exactly on non-empty lists and
-- returns Nothing on empty — never bottom.
prop_safeHeadTotal :: Property
prop_safeHeadTotal = property $ do
  xs <- forAll genInts
  case safeHead xs of
    Nothing -> xs === []
    Just x -> x === head xs

-- | REQ-002: clamp output always within bounds for any lo/hi/x.
prop_clampBounds :: Property
prop_clampBounds = property $ do
  lo <- forAll (Gen.int (Range.linear (-100) 100))
  hi <- forAll (Gen.int (Range.linear (-100) 100))
  x <- forAll (Gen.int (Range.linear (-1000) 1000))
  let c = clamp lo hi x
  if lo > hi
    then c === lo
    else do
      assert (c >= lo)
      assert (c <= hi)

tests :: TestTree
tests =
  testGroup
    "Omni.Core"
    [ testProperty "safeHead total" prop_safeHeadTotal,
      testProperty "clamp bounds" prop_clampBounds
    ]

main :: IO ()
main = defaultMain tests

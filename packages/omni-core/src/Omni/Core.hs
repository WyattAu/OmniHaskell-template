-- | Leaf primitives for the OmniHaskell workspace.
--
-- The L0 pattern made concrete: zero workspace dependencies, total
-- functions (returning 'Maybe' instead of partial ones), and
-- requirement-tagged properties (see REQUIREMENTS.md at the repo root).
module Omni.Core
  ( -- * Total list access
    safeHead,
    -- * Bounded numbers
    clamp,
  )
where

-- | REQ-001: total head — 'Nothing' instead of a crash on empty lists.
safeHead :: [a] -> Maybe a
safeHead [] = Nothing
safeHead (x : _) = Just x

-- | REQ-002: clamp @lo <= x <= hi@. Returns 'lo' when @lo > hi@
-- (documented, not hidden).
clamp :: Ord a => a -> a -> a -> a
clamp lo hi
  | lo > hi = const lo
  | otherwise = max lo . min hi

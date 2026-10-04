-- | Example executable: demonstrate the workspace pattern — binaries
-- compose on packages, never duplicate them.
module Main (main) where

import Omni.Core (safeHead)
import System.Environment (getArgs)
import System.Exit (exitFailure)

main :: IO ()
main = do
  args <- getArgs
  case safeHead args of
    Just name -> putStrLn ("hello, " <> name)
    Nothing -> do
      putStrLn "usage: omni-app <name>"
      exitFailure

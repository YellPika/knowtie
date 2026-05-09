{-# LANGUAGE BlockArguments #-}

module Main (main) where

import Data.Aeson (Value, eitherDecodeFileStrict, encodeFile)
import Data.HashMap.Lazy qualified as HashMap
import Data.List (stripPrefix)
import Data.Map qualified as Map
import Data.Maybe (fromJust, fromMaybe)
import Data.Traversable (for)
import Development.Shake (
  ShakeOptions (shakeFiles),
  Stdout (Stdout),
  cmd,
  getDirectoryFiles,
  liftIO,
  need,
  phony,
  putInfo,
  removeFilesAfter,
  shakeArgs,
  shakeOptions,
  shakeThreads,
  writeFile',
  (%>),
  (<//>),
 )
import Development.Shake.Config (readConfigFile, usingConfig)
import Development.Shake.FilePath (
  dropExtension,
  (-<.>),
  (</>),
 )
import System.IO.Error (catchIOError, isDoesNotExistError)

main ∷ IO ()
main = do
  cfg ←
    readConfigFile "knowtie.cfg" `catchIOError` \e →
      if isDoesNotExistError e
        then pure mempty
        else ioError e
  let bin = fromMaybe ".knowtie" (HashMap.lookup "INDEX_DIRECTORY" cfg)
  shakeArgs shakeOptions{shakeThreads = 0, shakeFiles = bin} do
    usingConfig cfg

    phony "build" do
      need [bin </> "index.json"]

    phony "clean" do
      removeFilesAfter bin ["//*"]

    bin </> "index.json" %> \out → do
      sources ← getDirectoryFiles "" ["//*.typ"]
      need [bin </> "index" </> src -<.> "json" | src ← sources]

      putInfo ("Compiling " ++ out)
      objects ←
        Map.fromList <$> for sources \src → do
          res ← liftIO (eitherDecodeFileStrict (bin </> "index" </> src -<.> "json"))
          case res of
            Left e → fail e
            Right x → pure (dropExtension src, x ∷ Value)
      liftIO (encodeFile out objects)

    bin </> "index" <//> "*.json" %> \out → do
      let src = fromJust (stripPrefix (bin </> "index/") out) -<.> "typ"
      need [src, bin </> "fake-index.json"]

      Stdout result ← cmd "typst query --input" ("index=" </> bin </> "fake-index.json") "--root . --field value" src "<metadata>"
      writeFile' out result

    bin </> "fake-index.json" %> \out → do
      writeFile' out "{}"

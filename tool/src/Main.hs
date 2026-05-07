{-# LANGUAGE BlockArguments #-}

module Main (main) where

import Data.Aeson (Value, eitherDecodeFileStrict, encodeFile)
import Data.Map qualified as Map
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
 )
import Development.Shake.FilePath (
  dropDirectory1,
  dropExtension,
  (-<.>),
  (</>),
 )

main ∷ IO ()
main = shakeArgs shakeOptions{shakeThreads = 0, shakeFiles = "bin"} do
  phony "build" do
    need ["bin/index.json"]

  phony "clean" do
    removeFilesAfter "bin" ["//*"]

  "bin/index.json" %> \out → do
    sources ← getDirectoryFiles "" ["//*.typ"]
    need ["bin" </> src -<.> "json" | src ← sources]

    putInfo ("Compiling " ++ out)
    objects ←
      Map.fromList <$> for sources \src → do
        res ← liftIO (eitherDecodeFileStrict ("bin" </> src -<.> "json"))
        case res of
          Left e → fail e
          Right x → pure (dropExtension src, x ∷ Value)
    liftIO (encodeFile out objects)

  "bin//*.json" %> \out → do
    let src = dropDirectory1 out -<.> "typ"
    need [src]

    Stdout result ← cmd "typst query --root . --field value" src "<metadata>"
    writeFile' out result

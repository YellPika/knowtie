{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE DerivingStrategies #-}

module Main (main) where

import Data.Aeson (
  FromJSON (..),
  Options (..),
  Value (..),
  defaultOptions,
  eitherDecodeFileStrict,
  eitherDecodeStrictText,
  encodeFile,
  genericParseJSON,
 )
import Data.HashMap.Lazy qualified as HashMap
import Data.List (stripPrefix)
import Data.Map (Map)
import Data.Map qualified as Map
import Data.Maybe (fromJust, fromMaybe)
import Data.Text qualified as Text
import Data.Traversable (for)
import Development.Shake (
  ShakeOptions (shakeFiles),
  Stdout (Stdout),
  StdoutTrim (..),
  cmd,
  cmd_,
  getDirectoryFiles,
  getEnv,
  liftIO,
  need,
  phony,
  putInfo,
  removeFilesAfter,
  shakeArgs,
  shakeOptions,
  shakeThreads,
  writeFile',
  writeFileLines,
  (%>),
  (<//>),
 )
import Development.Shake.Config (getConfig, readConfigFile, usingConfig)
import Development.Shake.FilePath (
  dropExtension,
  (-<.>),
  (</>),
 )
import GHC.Generics (Generic)
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

    phony "new" do
      StdoutTrim name ← cmd "mktemp XXXX.typ"
      StdoutTrim author ← cmd "git config user.name"
      writeFileLines
        name
        [ "#import \"@local/knowtie:1.0.0\": *"
        , "#show: template.with("
        , "  " ++ show (dropExtension name) ++ ","
        , "  author: " ++ show (author ∷ String) ++ ","
        , "  title: [New Note],"
        , ")"
        ]
      editor ← getConfig "EDITOR" >>= maybe (getEnv "EDITOR" >>= maybe (pure "code") pure) pure
      cmd_ editor name

    phony "init" do
      writeFileLines "knowtie.cfg" ["EDITOR=code"]
      writeFileLines ".gitignore" [".knowtie"]
      cmd_ "git init --initial-branch=main"
      cmd_ "git add knowtie.cfg .gitignore"
      cmd_ "git commit -am" ["Initial Commit"]

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
          deps = bin </> "deps" </> src -<.> "json"
      need [src, deps]

      mdeps ← liftIO (eitherDecodeFileStrict deps)
      either fail (need . inputs) mdeps

      Stdout result ← cmd "typst query --root . --field value" src "<metadata>"
      case eitherDecodeStrictText @[Map String Value] (Text.pack result) of
        Left e → fail e
        Right xs
          | any ((== Just (String (Text.pack "modified"))) . Map.lookup "type") xs → writeFile' out result
          | otherwise → do
              Stdout result' ← cmd "git log -1 --follow --format=%ad --date" ["format:{\"day\": %-d, \"month\": %-m, \"year\": %-Y}"] src
              case eitherDecodeStrictText (Text.pack result') of
                Left _ → writeFile' out result
                Right d → liftIO (encodeFile out (Map.fromList [("type", String (Text.pack "modified")), ("value", d)] : xs))

    bin </> "deps" <//> "*.json" %> \out → do
      let src = fromJust (stripPrefix (bin </> "deps/") out) -<.> "typ"
      need [src]

      cmd_ "typst compile --root . --format svg --deps" out src "/dev/null"

newtype Dependencies = Dependencies {inputs ∷ [FilePath]}
  deriving Generic

instance FromJSON Dependencies where
  parseJSON = genericParseJSON defaultOptions{rejectUnknownFields = True}

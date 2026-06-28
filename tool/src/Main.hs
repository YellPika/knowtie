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
  Action,
  CmdOption (..),
  Exit (..),
  ShakeOptions (shakeFiles),
  Stderr (..),
  Stdout (Stdout),
  StdoutTrim (..),
  cmd,
  cmd_,
  getDirectoryFiles,
  getEnv,
  liftIO,
  need,
  phony,
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
      writeFileLines
        name
        [ "#import \"@local/knowtie:1.0.0\": *"
        , "#show: template.with("
        , "  " ++ show (dropExtension name) ++ ","
        , "  title: [New Note],"
        , "  index: load-index(" ++ show ("/" </> bin </> "index.json") ++ "),"
        , ")"
        ]
      editor ← getConfig "EDITOR" >>= maybe (getEnv "EDITOR" >>= maybe (pure "code") pure) pure
      cmd_ [editor] [name]

    phony "init" do
      writeFileLines "knowtie.cfg" ["EDITOR=code"]
      writeFileLines ".gitignore" [".knowtie"]
      writeFileLines
        (".vscode" </> "extensions.json")
        [ "{"
        , "  \"recommendations\": ["
        , "    \"myriad-dreamin.tinymist\","
        , "    \"Gruntfuggly.triggertaskonsave\""
        , "  ],"
        , "}"
        ]
      writeFileLines
        (".vscode" </> "settings.json")
        [ "{"
        , "  \"triggerTaskOnSave.tasks\": {"
        , "    \"build\": ["
        , "      \"**/*.typ\","
        , "    ],"
        , "  },"
        , "}"
        ]
      writeFileLines
        (".vscode" </> "tasks.json")
        [ "{"
        , "  // See https://go.microsoft.com/fwlink/?LinkId=733558"
        , "  // for the documentation about the tasks.json format"
        , "  \"version\": \"2.0.0\","
        , "  \"tasks\": ["
        , "    {"
        , "      \"label\": \"build\","
        , "      \"type\": \"shell\","
        , "      \"command\": \"knowtie build\","
        , "      \"group\": {"
        , "        \"kind\": \"build\","
        , "        \"isDefault\": true"
        , "      },"
        , "      \"presentation\": {"
        , "        \"echo\": true,"
        , "        \"reveal\": \"never\","
        , "        \"focus\": false,"
        , "        \"panel\": \"shared\","
        , "        \"showReuseMessage\": true,"
        , "        \"clear\": false"
        , "      }"
        , "    }"
        , "  ]"
        , "}"
        ]
      cmd_ "git init --initial-branch=main"
      cmd_ "git add knowtie.cfg .gitignore .vscode"
      cmd_ "git commit -am" ["Initial Commit"]
      need ["build"]

    bin </> "index.json" %> \out → do
      sources ← getDirectoryFiles "" ["//*.typ"]
      need [bin </> "index" </> src -<.> "json" | src ← sources]

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
      either fail (need . filter (/= bin </> "index.json") . inputs) mdeps

      cmd_ (Traced "") "touch -a" [bin </> "index.json"]
      (Stdout result, Stderr (_ ∷ String), Exit _) ←
        cmd
          (Traced "typst [query]")
          "typst query --root . --field value"
          [src]
          "<metadata>"
      case eitherDecodeStrictText @[Map String Value] (Text.pack result) of
        Left e
          | result == "" → writeFile' out "[]"
          | otherwise → fail e
        Right xs → do
          ys ← addModified src xs
          zs ← addAuthor src ys
          liftIO (encodeFile out zs)

    bin </> "deps" <//> "*.json" %> \out → do
      let src = fromJust (stripPrefix (bin </> "deps/") out) -<.> "typ"
      need [src]

      cmd_ (Traced "") "touch -a" [bin </> "index.json"]
      (Exit _, Stdout (_ ∷ String), Stderr (_ ∷ String)) ←
        cmd
          (Traced "typst [deps]")
          "typst compile --root . --format svg --deps"
          [out]
          [src]
          "/dev/null"
      pure ()

data Dependencies = Dependencies
  { inputs ∷ [FilePath]
  , outputs ∷ [FilePath]
  }
  deriving Generic

instance FromJSON Dependencies where
  parseJSON = genericParseJSON defaultOptions{rejectUnknownFields = True}

addModified ∷ FilePath → [Map String Value] → Action [Map String Value]
addModified src obj
  | any ((== Just (String (Text.pack "modified"))) . Map.lookup "type") obj = do
      pure obj
  | otherwise = do
      Stdout date ← cmd (Traced "") "git log -1 --follow --format=%ad --date" ["format:{\"day\": %-d, \"month\": %-m, \"year\": %-Y}"] src
      case eitherDecodeStrictText (Text.pack date) of
        Left _ → pure obj
        Right date' → pure (Map.fromList [("type", String (Text.pack "modified")), ("value", date')] : obj)

addAuthor ∷ FilePath → [Map String Value] → Action [Map String Value]
addAuthor src obj
  | any ((== Just (String (Text.pack "author"))) . Map.lookup "type") obj = do
      pure obj
  | otherwise = do
      StdoutTrim author ← cmd (Traced "") "git log -1 --follow --format=%an" src
      if author == ""
        then pure obj
        else pure (Map.fromList [("type", String (Text.pack "author")), ("value", String (Text.pack author))] : obj)

module LanguageServer.IdePurescript.Types
  ( CommandHandler
  , CacheDb
  , ServerState(..)
  , ServerStateRec
  , DiagnosticState
  , RebuildRunning(..)
  ) where

import Prelude

import Data.Map (Map)
import Data.Maybe (Maybe)
import Data.Newtype (class Newtype)
import Effect.Aff (Aff, Fiber)
import Effect.Timer (TimeoutId)
import Foreign (Foreign)
import IdePurescript.Modules (State) as Modules
import IdePurescript.PscIdeServer (Port)
import LanguageServer.Protocol.TextDocument (TextDocument)
import LanguageServer.Protocol.Types (ClientCapabilities, Connection, Diagnostic, DocumentStore, DocumentUri, Settings)
import PscIde.Command (RebuildError)
import PureScript.CST (RecoveredParserResult)
import PureScript.CST.Types (Module)

type DiagnosticState = Map DocumentUri
  { errors :: Array RebuildError
  , diagnostics :: Array Diagnostic
  , onType :: Boolean {- if diagnostics came for not saved yet file -}
  }

type CacheDb = { path :: String, source :: String }

data RebuildRunning
  = FullBuild
  | FastRebuild (Map DocumentUri TextDocument)
  | DiagnosticsRebuild (Map DocumentUri TextDocument)

type ServerStateRec =
  { port :: Maybe Port
  , root :: Maybe String
  , conn :: Maybe Connection
  , clientCapabilities :: Maybe ClientCapabilities
  , deactivate :: Aff Unit
  --
  , runningRebuild ::
      Maybe { fiber :: Fiber Unit, uri :: DocumentUri, version :: Number }
  --
  , rebuildRunning :: Maybe RebuildRunning
  , fastRebuildQueue :: Map DocumentUri TextDocument
  , diagnosticsQueue :: Map DocumentUri TextDocument
  , fullBuildWaiting :: Maybe { progress :: Boolean }
  --
  , savedCacheDb :: Maybe CacheDb
  , revertCacheDbTimeout :: Maybe TimeoutId

  -- `modules` store "currently active in the editor" module state (imports and
  -- used identifiers). It is updated on any handled event related to to active
  -- document in the editor.
  , modules :: Modules.State

  , modulesFile :: Maybe DocumentUri
  , diagnostics :: DiagnosticState
  , parsedModules ::
      Map DocumentUri
        { version :: Number
        , parsed :: RecoveredParserResult Module
        , document :: TextDocument
        }
  }

newtype ServerState = ServerState ServerStateRec

derive instance newtypeServerState :: Newtype ServerState _

type CommandHandler a =
  DocumentStore -> Settings -> ServerState -> Array Foreign -> Aff a
module Types exposing 
  ( View(..)
  , Msg(..)
  , GameSettings
  , AppConfig
  , TempInGameMessages
  , Model
  , GameSettingsMsg(..)
  , GameSettingsModel
  , GameStateModel
  , initialModel
  , GameMessage(..)
  , GameScore
  , PlayerScore
  , PlayerRoundRecap
  , GameQuestion
  , PossibleResponse
  , Log
  , Logs
  , IGMessage
  )

import Json.Encode exposing (Value, object, string)
import Http exposing (Error(..))
import Time

type View 
  = LobbyView
  | PlayerLobbyView
  | GameView
  | GameFinishedView

type alias GameSettings = 
  { name: String
  , timeout: Int
  , numberOfQuestions: Int
  }

type alias AppConfig =
  { api_url : String
  }

type alias TempInGameMessages =
  { text: String
  , color: String
  , timer: Int
  , top: Int
  , left: Int
  }

type alias Model =
    { view: View
    , errorMessage: String
    , appConfig: AppConfig
    , logs: List Log
    , gameId: String
    , playerName: String
    , playerColor: String
    , isReady: Bool
    , isJoined: Bool
    , timeout: String
    , numberOfQuestions: String
    , currentQuestion : Maybe GameQuestion
    , currentChoice: Int
    , finalScore: GameScore
    , currentRecap: PlayerRoundRecap
    , otherPlayersRecap: List PlayerRoundRecap
    , timeElapsed: Int
    , displayedMessages: List TempInGameMessages
    }

type Msg
    = GameEvent Value
    | SubmitAnswer Int
    | JoinGame
    | GameReady
    | CreateGame
    | GameCreated (Result Http.Error String)
    | LobbyToPlayerLobby
    | PlayerLobbyToGame
    | RandomGameName String
    | RandomPlayerName String
    | GameSettingsMsg GameSettingsMsg
    | DismissError
    | Tick Time.Posix
    | ReInitGame
    | PlayerSendSmiley String

type GameSettingsMsg
  = ChangePlayerName String
  | ChangeQuestionNumber String
  | ChangeTimeout String
  | ChangeGameId String

type alias GameSettingsModel r =
  { r 
    | playerName: String
    , gameId: String
    , timeout: String
    , numberOfQuestions: String
  }

type alias GameStateModel r =
  { r 
    | isReady: Bool
    , isJoined: Bool
    , currentQuestion: Maybe GameQuestion
    , currentChoice: Int
    , finalScore: GameScore
    , currentRecap: PlayerRoundRecap
  }

type GameMessage
  = NextQuestion GameQuestion
  | RoundRecap (List PlayerRoundRecap)
  | GameFinished GameScore
  | ErrorParse String
  | LobbyLog Logs
  | InGameMessage IGMessage

type alias IGMessage = 
  { text: String
  , color: String
  , left: Int
  , top: Int
  }

type alias Logs =
  {logs: (List Log)}

type alias Log =
  { text: String
  , color: String
  }

type alias GameScore = 
  { score: List PlayerScore
  }
type alias PlayerScore = 
  { playerName: String
  , score: Int
  }

type alias PlayerRoundRecap =
  { playerName: String
  , answer: Int
  , goodAnswer: Int
  , questionId: String
  , color: String
  }

type alias GameQuestion = 
  { id: String
  , title: String
  , possibleResponses: List PossibleResponse
  }
type alias PossibleResponse =
  { id: Int
  , text: String
  }

initialModel config =
  { view = LobbyView
  , gameId = ""
  , playerName = ""
  , playerColor = "#FFF"
  , currentQuestion = Nothing
  , currentChoice = -1
  , finalScore = {score = []}
  , isReady = False
  , isJoined = False
  , errorMessage = ""
  , timeout = "30"
  , numberOfQuestions = "10"
  , appConfig = config
  , currentRecap = {playerName= "", answer=-1, goodAnswer=-1, questionId="-", color=""}
  , otherPlayersRecap = []
  , logs = []
  , timeElapsed = 0
  , displayedMessages = []
  }
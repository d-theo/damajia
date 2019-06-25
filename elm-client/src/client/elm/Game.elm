module Game exposing (GameMessage(..),GameScore,PlayerScore,PlayerRoundRecap,GameQuestion,PossibleResponse, parseGameEvent)

import Json.Encode exposing (Value, object)
import Json.Decode exposing (Decoder, field, string, map4, map3, list, map2, int, map, oneOf, decodeValue, errorToString)

type GameMessage
  = NextQuestion GameQuestion
  | RoundRecap (List PlayerRoundRecap)
  | GameFinished GameScore
  | ErrorParse String
  | LobbyLog Log

type alias Log =
  {info: String}

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

parseGameEvent: Value -> GameMessage
parseGameEvent value = 
  let 
    parsed = decodeValue gameMessage value
    data = case parsed of
      Ok evt -> evt
      Err err -> ErrorParse (errorToString err)
  in
    data

gameMessage: Decoder GameMessage
gameMessage = 
  oneOf
    [ map NextQuestion gameQuestion
    , map GameFinished gameScore
    , map RoundRecap roundRecap
    , map LobbyLog lobbyLog
    ]

lobbyLog: Decoder Log
lobbyLog = 
  map Log (field "info" string)

errorParse: GameMessage
errorParse = ErrorParse "error parsing"

possibleResponses: Decoder PossibleResponse
possibleResponses = 
  map2 PossibleResponse
    (field "id" int)
    (field "text" string)

gameQuestion: Decoder GameQuestion
gameQuestion = 
  map3 GameQuestion
    (field "id" string)
    (field "title" string)
    (field "possibleResponses" (list possibleResponses))

gameScore: Decoder GameScore
gameScore = 
  map GameScore
    (field "score" (list playerScore))

playerScore: Decoder PlayerScore
playerScore = 
  map2 PlayerScore
    (field "playerName" string)
    (field "score" int)

roundRecap: Decoder (List PlayerRoundRecap)
roundRecap = Json.Decode.list playerRoundRecap

playerRoundRecap: Decoder PlayerRoundRecap
playerRoundRecap =
  map4 PlayerRoundRecap
    (field "playerName" string)
    (field "answer" int)
    (field "goodAnswer" int)
    (field "questionId" string)
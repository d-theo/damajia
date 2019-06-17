port module Main exposing (Model, Msg(..), init, main, receiveMessage, sendMessage, subscriptions, update, view)

import Browser
import Html exposing (Html, button, div, input, li, text, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode exposing (Decoder, field, string, map3, list, map2, int, map, oneOf, decodeValue)
import Json.Encode exposing (Value)


-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    receiveMessage GameEvent


port sendMessage : (String,String) -> Cmd msg


port receiveMessage : (Value -> msg) -> Sub msg

-- MODEL
type alias Model =
    { messages : List String
    , gameId: String
    , playerName: String
    , currentQuestion : Maybe GameQuestion
    , currentChoice: Int
    , finalScore: Maybe GameScore
    , isReady: Bool
    , errorMessage: String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { messages = []
      , gameId = "test"
      , playerName = "theo"
      , currentQuestion = Nothing
      , currentChoice = -1
      , finalScore = Nothing
      , isReady = False
      , errorMessage = "-"
      }
    , Cmd.none
    )

type Msg
    = GameEvent Value
    | SubmitAnswer Int
    | ChangePlayerName String
    | JoinGame
    | GameReady

type GameMessage
  = NextQuestion GameQuestion
  | GameFinished GameScore
  | ErrorParse String
-- JSON Decode

gameMessage: Decoder GameMessage
gameMessage = 
  oneOf
    [ map NextQuestion gameQuestion
    , map GameFinished gameScore
    ]

errorParse: GameMessage
errorParse = ErrorParse "error parsing"

type alias GameScore = 
  { score: List PlayerScore
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

type alias PlayerScore = 
  { playerName: String
  , score: Int
  }

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
    (field "possibleResponse" (list possibleResponses))

gameScore: Decoder GameScore
gameScore = 
  map GameScore
    (field "score" (list playerScore))

playerScore: Decoder PlayerScore
playerScore = 
  map2 PlayerScore
    (field "playerName" string)
    (field "score" int)


parseGameEvent: Value -> GameMessage
parseGameEvent value = 
  let 
    parsed = decodeValue gameMessage value
      |> Result.withDefault errorParse
  in
    parsed

-- UPDATE game_finished next_question

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GameEvent rawEvent ->
          let 
            gameEvent = parseGameEvent rawEvent
          in 
            case gameEvent of
                NextQuestion question ->
                  ({model | currentQuestion = (Just question)}, Cmd.none)
                GameFinished score ->
                  ({model | finalScore = (Just score)}, Cmd.none)
                ErrorParse err ->
                  ({model | errorMessage = err}, Cmd.none)
        ChangePlayerName playerName ->
            ( { model | playerName = playerName }, Cmd.none )
        JoinGame ->
            ( model 
            , if model.playerName == "" then
                Cmd.none
              else
                sendMessage (
                  "join",
                  (String.join ","
                  [ model.playerName
                  , model.gameId
                  ]
                  ))
            )
        GameReady ->
          ({model | isReady = not model.isReady}
          , sendMessage (
            "ready",
            (String.join ","
            [ model.playerName
            , model.gameId
            , if model.isReady then "false" else "true"
            ]
            ))
          )
        SubmitAnswer i ->
          ({model | currentChoice = i}, sendMessage (
            "submit",
            (String.join "," 
            [ model.playerName
            , model.gameId
            , (Maybe.withDefault {title = "", id = "", possibleResponses = []} model.currentQuestion).id
            , String.fromInt model.currentChoice]
            )
          ))



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ ul [ id "messages" ] (printQuestion model.currentQuestion)
        , text model.errorMessage
        , div [ id "chatform" ]
            [ input [ value model.playerName, onInput ChangePlayerName ] []
            , button [ onClick JoinGame ] [ text "JoinGame" ]
            , button [ onClick GameReady ] [ text "Ready !" ]
            ]
        ]

printQuestion : Maybe GameQuestion -> List (Html Msg)
printQuestion question =
  case question of 
    Nothing -> []
    Just q -> (List.map (\choice -> li [onClick (SubmitAnswer choice.id)] [ text choice.text ]) q.possibleResponses)

unwrapQuestion: Maybe GameQuestion -> GameQuestion
unwrapQuestion question =
  case question of 
    Nothing -> {title = "", id = "", possibleResponses = []}
    Just q -> q
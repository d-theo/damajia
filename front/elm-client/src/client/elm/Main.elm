port module Main exposing (Model, Msg(..), init, main, receiveMessage, sendMessage, subscriptions, update, view)

import Browser
import Html exposing (Html, button, div, input, li, text, ul, h3, label, h4, b)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode exposing (Decoder, field, string, map4, map3, list, map2, int, map, oneOf, decodeValue, errorToString)
import Json.Encode exposing (Value, object)
import Random.String
import Random.Char
import Random
import List.Extra


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
type View 
  = LobbyView
  | PlayerLobbyView
  | GameView

type alias Model =
    { messages : List String
    , view: View
    , gameId: String
    , playerName: String
    , currentQuestion : Maybe GameQuestion
    , currentChoice: Int
    , finalScore: Maybe GameScore
    , isReady: Bool
    , errorMessage: String
    , timeout: Int
    , numberOfQuestions: Int
    , currentRecap: PlayerRoundRecap
    }

type alias GameSettings = 
  { name: String
  , timeout: Int
  }

init : () -> ( Model, Cmd Msg )
init _ =
    ( { messages = []
      , view = LobbyView
      , gameId = "test"
      , playerName = "theo"
      , currentQuestion = Nothing
      , currentChoice = -1
      , finalScore = Nothing
      , isReady = False
      , errorMessage = ""
      , timeout = 30
      , numberOfQuestions = -1
      , currentRecap = {playerName= "", answer=-1, goodAnswer=-1, questionId="-"}
      }
    , Cmd.batch 
      [ Random.generate RandomGameName fiveLetterEnglishWord
      , Random.generate RandomPlayerName fiveLetterEnglishWord
      ]
    )

type Msg
    = GameEvent Value
    | SubmitAnswer Int
    | ChangePlayerName String
    | JoinGame
    | GameReady
    | ChangeGameId String
    | ChangeQuestionNumber String
    | ChangeTimeout String
    | CreateGame
    | GameCreated (Result Http.Error String)
    | LobbyToPlayerLobby
    | PlayerLobbyToGame
    | RandomGameName String
    | RandomPlayerName String

type GameMessage
  = NextQuestion GameQuestion
  | RoundRecap (List PlayerRoundRecap)
  | GameFinished GameScore
  | ErrorParse String
-- JSON Decode

gameMessage: Decoder GameMessage
gameMessage = 
  oneOf
    [ map NextQuestion gameQuestion
    , map GameFinished gameScore
    , map RoundRecap roundRecap
    ]

errorParse: GameMessage
errorParse = ErrorParse "error parsing"

type alias GameScore = 
  { score: List PlayerScore
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

parseGameEvent: Value -> GameMessage
parseGameEvent value = 
  let 
    parsed = decodeValue gameMessage value
    data = case parsed of
      Ok evt -> evt
      Err err -> ErrorParse (errorToString err)
  in
    data

-- UPDATE game_finished next_question

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    RandomGameName randomId -> 
      ({model | gameId = randomId}, Cmd.none)
    RandomPlayerName randomId -> 
      ({model | playerName = randomId}, Cmd.none)
    GameEvent rawEvent ->
      let 
        gameEvent = parseGameEvent rawEvent
      in 
        case gameEvent of
            NextQuestion question ->
              ({model | currentQuestion = (Just question)}, Cmd.none)
            RoundRecap recap ->
              ({model | currentRecap = (myRecap model.playerName model.currentQuestion recap)}, Cmd.none)
            GameFinished score ->
              ({model | finalScore = (Just score)}, Cmd.none)
            ErrorParse err ->
              ({model | errorMessage = err}, Cmd.none)
    ChangePlayerName playerName ->
        ( { model | playerName = playerName }, Cmd.none )
    ChangeGameId gameId -> ( { model | gameId = gameId }, Cmd.none )
    ChangeQuestionNumber numberOfQuestions -> 
      ( { model | numberOfQuestions = Maybe.withDefault -1 (String.toInt numberOfQuestions) }, Cmd.none )
    ChangeTimeout timeout -> 
      ( { model | timeout = Maybe.withDefault -1 (String.toInt timeout) }, Cmd.none )
    GameCreated res -> 
      case res of
        Ok gameId ->
          ({model | gameId = gameId, view = PlayerLobbyView}, Cmd.none)
        Err m ->
          (model, Cmd.none)
    CreateGame ->
      (model, (createGame {name= model.gameId, timeout= model.timeout}))
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
      ({model | isReady = not model.isReady, view = GameView}
      , sendMessage (
        "ready",
        (String.join ","
        [ model.playerName
        , model.gameId
        , if model.isReady then "false" else "true"
        ]
        ))
      )
    LobbyToPlayerLobby -> ({model | view = PlayerLobbyView}, Cmd.none)
    PlayerLobbyToGame -> ({model | view = GameView}, Cmd.none)
    SubmitAnswer i ->
      ({model | currentChoice = i}, sendMessage (
        "submit",
        (String.join "," 
        [ model.playerName
        , model.gameId
        , (Maybe.withDefault {title = "", id = "", possibleResponses = []} model.currentQuestion).id
        , String.fromInt i]
        )
      ))

joinGame: Model -> Cmd Msg
joinGame model = 
  if model.playerName == "" then
    Cmd.none
  else
    sendMessage (
      "join",
      (String.join ","
      [ model.playerName
      , model.gameId
      ]
      ))

myRecap: String -> (Maybe GameQuestion) -> (List PlayerRoundRecap) -> PlayerRoundRecap
myRecap myName question currentRoundRecap = 
  case question of 
      Nothing -> 
        Maybe.withDefault (PlayerRoundRecap myName -1 -1 "")
        (List.Extra.find (\recap -> recap.playerName == myName) currentRoundRecap)
      Just q -> 
        Maybe.withDefault (PlayerRoundRecap myName -1 -1 q.id)
        (List.Extra.find (\recap -> recap.playerName == myName) currentRoundRecap)

-- VIEW

view : Model -> Html Msg
view model = 
  case model.view of
    LobbyView -> lobbyView model
    PlayerLobbyView -> playerLobbyView model
    GameView -> gameView model

lobbyView: Model -> Html Msg
lobbyView model = 
  div [ class "d-flex flex-column" ]
    [ h3 []
        [ text "welcome to the Damajia !" ]
    , div []
        [ h4 []
            [ text "Create a game" ]
        , div [ class "d-flex flex-column" ]
            [ div []
                [ label [ class "small text-sm text-uppercase font-weight-bolder" ]
                    [ text "game name" ]
                , input [ onInput ChangeGameId, attribute "autocomplete" "off", class "form-control", name "newgameid", placeholder "game id", type_ "text", value model.gameId]
                    []
                , text "            "
                ]              
            , div []
                [ label [ class "small text-uppercase font-weight-bolder" ]
                    [ text "number of questions" ]
                , input [ onInput ChangeQuestionNumber, attribute "autocomplete" "off", class "form-control", name "newgamenb", type_ "number", value "10" ]
                    []
                , text "            "
                ]
            , div []
                [ label [ class "small text-uppercase font-weight-bolder" ]
                    [ text "timeout" ]
                , input [ onInput ChangeTimeout, attribute "autocomplete" "off", class "form-control", name "newgamenb", type_ "number", value (String.fromInt model.timeout) ]
                    []
                , text "            "
                ]
            , div [ class "d-flex" ]
                [ button [ class "btn btn-info btn-block", onClick CreateGame ]
                    [ text "create" ]
                ]
            ]
        ]
    , div [ class "d-flex justify-content-center" ]
        [ h4 [ class "m-md" ]
            [ b []
                [ text "OR" ]
            ]
        ]
    , div []
        [ h4 []
            [ text "Join a game" ]
        , input [ onInput ChangeGameId, attribute "autocomplete" "off", class "form-control", name "gameid", placeholder "game id", type_ "text" ]
            []
        , button [onClick LobbyToPlayerLobby, class "btn btn-secondary btn-block" ]
            [ text "join" ]
        ]
    ]

createGame : GameSettings -> Cmd Msg
createGame settings =
  Http.post
    { url = "http://localhost:3001/quizz/"
    , body = Http.jsonBody (createGameSettings settings)
    , expect = Http.expectString GameCreated
    }

createGameSettings: GameSettings -> Value
createGameSettings settings = 
  object
    [ ("name", Json.Encode.string settings.name)
    , ("timeout", Json.Encode.int settings.timeout)
    ]

gameView: Model -> Html Msg
gameView model = 
  div []
    [ h4 []
        [ printQuestionTitle model.currentQuestion ]
    , ul [ class "d-flex flex-column" ]
        (printQuestionChoices model model.currentQuestion)
    ]

playerLobbyView: Model -> Html Msg
playerLobbyView model =
  div []
    [ label [ class "small text-uppercase font-weight-bolder" ]
        [ text "your name" ]
    , input [ onInput ChangePlayerName, attribute "autocomplete" "off", class "form-control", name "newgameplayer", type_ "text", placeholder "name", value model.playerName]
        []
    , button [ onClick JoinGame, class "btn btn-secondary btn-block" ]
      [ text "join game" ]
    , button [ onClick GameReady, class "btn btn-secondary btn-block" ]
      [ text "ready" ]
    ]

printQuestionChoices : Model -> Maybe GameQuestion -> List (Html Msg)
printQuestionChoices model question =
  case question of 
    Nothing -> []
    Just q ->
      if q.id == model.currentRecap.questionId then
        (List.map (\choice -> li [class ("hoverable alert alert-"++(questionGoodColor choice.id model.currentRecap.answer model.currentRecap.goodAnswer)), onClick (SubmitAnswer choice.id)] [ text choice.text ]) q.possibleResponses)
      else
        (List.map (\choice -> li [class "hoverable alert alert-primary", onClick (SubmitAnswer choice.id)] [ text choice.text ]) q.possibleResponses)

questionGoodColor: Int -> Int -> Int -> String
questionGoodColor answerId playerChoice goodAnswer = 
  if playerChoice == goodAnswer && answerId == playerChoice then "success"
  else if playerChoice == answerId && answerId /= goodAnswer then "danger"
  else if answerId == goodAnswer then "success"
  else "primary"

printQuestionTitle: Maybe GameQuestion -> Html Msg
printQuestionTitle question =
  case question of
    Nothing -> div [][text "Waiting all players to be ready..."]
    Just q -> text q.title

fiveLetterEnglishWord = Random.String.string 5 Random.Char.english
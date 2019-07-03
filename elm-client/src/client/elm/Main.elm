port module Main exposing (Model, Msg(..), init, main, receiveMessage, sendMessage, subscriptions, update, view)

import Browser
import Html exposing (Html, button, div, input, li, text, ul, h3, label, h4, b, h5)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http exposing (Error(..))
import Json.Decode exposing (Decoder, field, string, map4, map3, list, map2, int, map, oneOf, decodeValue, errorToString)
import Json.Encode exposing (Value, object)
import Random
import List.Extra
import Time
import Task
import Process
import Game exposing (GameMessage(..),GameScore,PlayerScore,PlayerRoundRecap,GameQuestion,PossibleResponse, parseGameEvent)
import RandomUtils exposing (fiveLetterEnglishWord)

-- MAIN
main =
  Browser.element
      { init = init
      , update = update
      , subscriptions = subscriptions
      , view = view
      }

-- NETWORK
subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch 
  [ receiveMessage GameEvent
  , Time.every 1000 Tick
  ]

port sendMessage : (String,String) -> Cmd msg
port receiveMessage : (Value -> msg) -> Sub msg

send : String -> List String -> Cmd msg
send msg array = sendMessage (msg, (String.join "," array)) -- hack: la lib ne permet d'envoyer que des strings, on parsera côté JS avec les ','

sendMessagePlayerJoin: String -> String -> Cmd msg
sendMessagePlayerJoin playerName gameId = send "join" [playerName, gameId]

sendMessagePlayerReady: String -> String -> Bool -> Cmd msg
sendMessagePlayerReady playerName gameId isReady = send "ready" [playerName, gameId, (if isReady then "false" else "true") ]

sendMessageSubmitAnswer: String -> String -> String -> Int -> Cmd msg
sendMessageSubmitAnswer playerName gameId questionid answerid = send "submit" [ playerName, gameId, questionid, String.fromInt answerid]

-- MODEL
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

type alias Model =
    { view: View
    , errorMessage: String
    , appConfig: AppConfig
    , logs: List String
    , gameId: String
    , playerName: String
    , isReady: Bool
    , isJoined: Bool
    , timeout: String
    , numberOfQuestions: String
    , currentQuestion : Maybe GameQuestion
    , currentChoice: Int
    , finalScore: GameScore
    , currentRecap: PlayerRoundRecap
    , timeElapsed: Int
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

init : AppConfig -> ( Model, Cmd Msg )
init config =
    ( { view = LobbyView
      , gameId = "test"
      , playerName = "theo"
      , currentQuestion = Nothing
      , currentChoice = -1
      , finalScore = {score = []}
      , isReady = False
      , isJoined = False
      , errorMessage = ""
      , timeout = "30"
      , numberOfQuestions = "10"
      , appConfig = config
      , currentRecap = {playerName= "", answer=-1, goodAnswer=-1, questionId="-"}
      , logs = []
      , timeElapsed = 0
      }
    , Cmd.batch 
      [ Random.generate RandomGameName fiveLetterEnglishWord
      , Random.generate RandomPlayerName fiveLetterEnglishWord
      ]
    )

-- UPDATE
setPlayerName: String -> GameSettingsModel r -> GameSettingsModel r
setPlayerName name game = {game | playerName = name}

setGameId: String -> GameSettingsModel r -> GameSettingsModel r
setGameId gameId game = {game | gameId = gameId}

setTimeout: String -> GameSettingsModel r -> GameSettingsModel r
setTimeout timeout game = {game | timeout = timeout}

setNumberOfQuestions: String -> GameSettingsModel r -> GameSettingsModel r
setNumberOfQuestions nb game = {game | numberOfQuestions = nb}

updateGameSettings: GameSettingsMsg -> Model -> ( Model, Cmd Msg )
updateGameSettings msg model = 
  case msg of 
    ChangePlayerName name ->(setPlayerName name model, Cmd.none )
    ChangeQuestionNumber nb ->(setNumberOfQuestions nb model, Cmd.none )
    ChangeTimeout timeout -> (setTimeout timeout model, Cmd.none )
    ChangeGameId id ->(setGameId id model, Cmd.none )

updateGame: Value -> Model -> ( Model, Cmd Msg )
updateGame msg model = 
  let
    gameEvent = parseGameEvent msg
  in
    case gameEvent of
      NextQuestion question -> ({model | currentQuestion = (Just question), currentChoice = -1, timeElapsed = 0}, Cmd.none)
      RoundRecap recap -> ({model | currentRecap = (myRecap model.playerName model.currentQuestion recap)}, Cmd.none)
      GameFinished score -> ({model | finalScore = score, view = GameFinishedView}, Cmd.none)
      ErrorParse err -> ({model | errorMessage = err}, Cmd.none)
      LobbyLog logs -> ({model | logs = logs.logs}, Cmd.none)

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    GameSettingsMsg smsg ->
      updateGameSettings smsg model
    RandomGameName randomId -> 
      ({model | gameId = randomId}, Cmd.none)
    RandomPlayerName randomId -> 
      ({model | playerName = randomId}, Cmd.none)
    GameEvent rawEvent ->
      updateGame rawEvent model
    GameCreated res -> 
      case res of
        Ok gameId ->
          ({model | gameId = gameId, view = PlayerLobbyView}, Cmd.none)
        Err m ->
          ({model | errorMessage = (errorToString m)}, (delay 5 DismissError))
    CreateGame ->
      (model, (createGame model.appConfig.api_url {name= model.gameId, timeout= Maybe.withDefault -1 (String.toInt model.timeout), numberOfQuestions=Maybe.withDefault -1 (String.toInt model.numberOfQuestions)}))
    JoinGame ->
        ( {model | isJoined = True}
        , if model.playerName == "" then
            Cmd.none
          else
            sendMessagePlayerJoin model.playerName model.gameId
        )
    GameReady ->
      ( {model | isReady = not model.isReady, view = GameView}
      , sendMessagePlayerReady model.playerName model.gameId model.isReady
      )
    SubmitAnswer answerId ->
      if model.currentChoice == -1 then
        ( {model | currentChoice = answerId}
        , sendMessageSubmitAnswer model.playerName model.gameId ((Maybe.withDefault {title = "", id = "", possibleResponses = []} model.currentQuestion).id) answerId
        )
      else 
        (model, Cmd.none)
    LobbyToPlayerLobby -> ({model | view = PlayerLobbyView}, Cmd.none)
    PlayerLobbyToGame -> ({model | view = GameView}, Cmd.none)
    DismissError -> ({model | errorMessage = ""}, Cmd.none)
    Tick _ -> ({model | timeElapsed = model.timeElapsed + 1}, Cmd.none)

delay : Float -> msg -> Cmd msg
delay time msg =
  Process.sleep (time*1000)
  |> Task.perform (\_ -> msg)

createGame : String -> GameSettings -> Cmd Msg
createGame url settings =
  Http.post
    { url = url ++ "/quizz/"
    , body = Http.jsonBody (createGameSettings settings)
    , expect = Http.expectString GameCreated
    }

createGameSettings: GameSettings -> Value
createGameSettings settings = 
  object
    [ ("name", Json.Encode.string settings.name)
    , ("timeout", Json.Encode.int settings.timeout)
    , ("numberOfquestions", Json.Encode.int settings.numberOfQuestions)
    ]

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
    GameFinishedView -> gameFinishedView model

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
                , input [ onInput (GameSettingsMsg << ChangeGameId), attribute "autocomplete" "off", class "form-control", name "newgameid", placeholder "game id", type_ "text", value model.gameId]
                    []
                , text "            "
                ]              
            , div []
                [ label [ class "small text-uppercase font-weight-bolder" ]
                    [ text "number of questions" ]
                , input [ onInput (GameSettingsMsg << ChangeQuestionNumber), attribute "autocomplete" "off", class "form-control", name "newgamenb", type_ "number", value model.numberOfQuestions ]
                    []
                , text "            "
                ]
            , div []
                [ label [ class "small text-uppercase font-weight-bolder" ]
                    [ text "timeout" ]
                , input [ onInput (GameSettingsMsg << ChangeTimeout), attribute "autocomplete" "off", class "form-control", name "newgamenb", type_ "number", value model.timeout ]
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
        , input [ onInput (GameSettingsMsg << ChangeGameId), attribute "autocomplete" "off", class "form-control", name "gameid", placeholder "game id", type_ "text" ]
            []
        , button [onClick LobbyToPlayerLobby, class "btn btn-secondary btn-block" ]
            [ text "join" ]
        ]
    , printError model.errorMessage
    ]

printError: String -> Html Msg
printError msg = 
  if String.isEmpty msg then div [class "popup"] [ text msg ]
  else div [class "popup popup--visible"] [ text msg ]

gameView: Model -> Html Msg
gameView model = 
  div []
    [ h4 []
        [ printQuestionTitle model.currentQuestion ]
    , ul [ class "d-flex flex-column" ]
        (printQuestionChoices model model.currentQuestion)
    , String.toInt model.timeout
       |> Maybe.withDefault 1
       |> displayTimer model.timeElapsed
    ]

displayTimer: Int -> Int -> Html Msg
displayTimer timeElapsed timeout =
  let
    normalizedTimer = (toFloat timeElapsed / toFloat timeout) * 100
     |> Basics.min 100
  in
    if timeElapsed > 0 then div [class "timer timer-animation", style "width" (String.fromFloat normalizedTimer++"%")] [ ]
    else div [class "timer", style "width" (String.fromFloat normalizedTimer++"%")] [ ]

playerLobbyView: Model -> Html Msg
playerLobbyView model =
  div []
    [ h5 [] [ text ("Your game id : "  ++ model.gameId) ]
    , label [ class "small text-uppercase font-weight-bolder" ]
        [ text "your name" ]
    , input [ onInput (GameSettingsMsg << ChangePlayerName), attribute "autocomplete" "off", class "form-control", name "newgameplayer", type_ "text", placeholder "name", disabled model.isJoined, value model.playerName]
        []
    , button [ onClick JoinGame, class ("mt-3 btn btn-block " ++ if model.isJoined then "btn-secondary" else "btn-primary"), disabled model.isJoined]
      [ text "join game" ]
    , button [ onClick GameReady, class ("btn btn-block "++if model.isReady then "btn-danger" else if model.isJoined then "btn-success" else "btn-secondary"), disabled (not model.isJoined) ]
      [ text (if model.isReady then "Not Ready" else "Ready") ]
    , ul [ class "d-flex flex-column" ]
        (List.map (\log -> li [] [ h5 [] [text log ]]) model.logs)
    , printError model.errorMessage
    ]

gameFinishedView: Model -> Html Msg
gameFinishedView model = 
  div []
    [ h4 []
        [ text "Game Finished !" ]
    , ul [ class "d-flex flex-column" ]
        (List.map (\playerScore -> li [class "alert alert-primary"] [ h5 [] [text (playerScore.playerName ++ " got " ++ (String.fromInt playerScore.score ++ " points")) ]]) model.finalScore.score)
    ]

printQuestionChoices : Model -> Maybe GameQuestion -> List (Html Msg)
printQuestionChoices model question =
  case question of 
    Nothing -> []
    Just q ->
      if q.id == model.currentRecap.questionId then
        (List.map (\choice -> li [class ("hoverable alert alert-"++(questionGoodColor choice.id model.currentRecap.answer model.currentRecap.goodAnswer)), onClick (SubmitAnswer choice.id)] [ text choice.text ]) q.possibleResponses)
      else
        (List.map (\choice -> li [class ("hoverable alert "++(colorQuestion choice.id model.currentChoice)), onClick (SubmitAnswer choice.id)] [ text choice.text ]) q.possibleResponses)

questionGoodColor: Int -> Int -> Int -> String
questionGoodColor answerId playerChoice goodAnswer = 
  if playerChoice == goodAnswer && answerId == playerChoice then "success"
  else if playerChoice == answerId && answerId /= goodAnswer then "danger"
  else if answerId == goodAnswer then "success"
  else "primary"

colorQuestion: Int -> Int -> String
colorQuestion choiceId selfChoiceId = if choiceId == selfChoiceId then "alert-secondary" else "alert-primary"

printQuestionTitle: Maybe GameQuestion -> Html Msg
printQuestionTitle question =
  case question of
    Nothing -> div [][text "Waiting all players to be ready..."]
    Just q -> text q.title

---- Utils

errorToString : Http.Error -> String
errorToString error =
    case error of
        BadUrl url ->
            "The URL " ++ url ++ " was invalid"
        Timeout ->
            "Unable to reach the server, try again"
        NetworkError ->
            "Unable to reach the server, check your network connection"
        BadStatus 500 ->
            "The server had a problem, try again later"
        BadStatus 400 ->
            "The game name already exists, try an other name."
        BadStatus _ ->
            "Unknown error"
        BadBody errorMessage ->
            errorMessage
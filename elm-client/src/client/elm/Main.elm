port module Main exposing (init, main, receiveMessage, sendMessage, subscriptions, update, view)

import Browser
import Html exposing (Html, button, div, input, li, text, ul, h3, label, h4, b, h5, span)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http exposing (Error(..))
import Json.Encode exposing (Value, object, string)
import Random
import List.Extra
import Time
import Task
import Process
import ServerDecoder exposing (parseServerEvent)
import RandomUtils exposing (fiveLetterEnglishWord)
import Types exposing (Model, Msg(..), View(..), AppConfig, GameSettingsModel, initialModel, GameSettingsMsg(..), TempInGameMessages, GameSettings, GameMessage(..),GameScore,PlayerScore,PlayerRoundRecap,GameQuestion,PossibleResponse, Log)
import GamePage exposing (gameView)
import HomePage exposing (lobbyView)
import LobbyPage exposing (playerLobbyView)

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

sendMessageSendSmiley: String -> String -> String -> Cmd msg
sendMessageSendSmiley playerName gameId smile = send "player_ingame_message" [ playerName, gameId, smile ]

init : AppConfig -> ( Model, Cmd Msg )
init config =
    ( (initialModel config)
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
    gameEvent = parseServerEvent msg
  in
    case gameEvent of
      NextQuestion question -> ({model | currentQuestion = (Just question), currentChoice = -1, timeElapsed = 0}, Cmd.none)
      RoundRecap recap -> ({model
       | currentRecap = (myRecap model.playerName model.currentQuestion recap)
       , otherPlayersRecap = (othersRecap model.playerName model.currentQuestion recap)}
       , Cmd.none)
      GameFinished score -> ({model | finalScore = score, view = GameFinishedView}, Cmd.none)
      ErrorParse err -> ({model | errorMessage = err}, Cmd.none)
      LobbyLog logs -> ({model | logs = logs.logs}, Cmd.none)
      InGameMessage message -> ({model | displayedMessages = model.displayedMessages ++ [{text = message.text, color = message.color, timer= 2, top=message.top, left= message.left}]}, Cmd.none)

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
    ReInitGame -> (initialModel model.appConfig, Cmd.batch [ Random.generate RandomGameName fiveLetterEnglishWord, Random.generate RandomPlayerName fiveLetterEnglishWord])
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
    PlayerSendSmiley smile -> (model, sendMessageSendSmiley model.playerName model.gameId smile)
    LobbyToPlayerLobby -> ({model | view = PlayerLobbyView}, Cmd.none)
    PlayerLobbyToGame -> ({model | view = GameView}, Cmd.none)
    DismissError -> ({model | errorMessage = ""}, Cmd.none)
    Tick _ -> ({model | timeElapsed = model.timeElapsed + 1,
        displayedMessages = minusOne model.displayedMessages |> filterExpiredMessage}
      , Cmd.none)

minusOne: List TempInGameMessages -> List TempInGameMessages
minusOne list = List.map (\msg -> {msg | timer = msg.timer - 1}) list

filterExpiredMessage: List TempInGameMessages -> List TempInGameMessages
filterExpiredMessage list = List.filter (\msg -> msg.timer > 0) list

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
        Maybe.withDefault (PlayerRoundRecap myName -1 -1 "" "")
        (List.Extra.find (\recap -> recap.playerName == myName) currentRoundRecap)
      Just q -> 
        Maybe.withDefault (PlayerRoundRecap myName -1 -1 q.id "")
        (List.Extra.find (\recap -> recap.playerName == myName) currentRoundRecap)

othersRecap: String -> (Maybe GameQuestion) -> (List PlayerRoundRecap) -> (List PlayerRoundRecap)
othersRecap myName question currentRoundRecap = 
  case question of 
        Nothing -> 
          List.filter (\recap -> recap.playerName /= myName) currentRoundRecap
        Just q -> 
          List.filter (\recap -> recap.playerName /= myName) currentRoundRecap
-- VIEW

view : Model -> Html Msg
view model = 
  case model.view of
    LobbyView -> lobbyView model
    PlayerLobbyView -> playerLobbyView model
    GameView -> gameView model
    GameFinishedView -> gameFinishedView model

gameFinishedView: Model -> Html Msg
gameFinishedView model = 
  div []
    [ h4 []
        [ text "Game Finished !" ]
    , ul [ class "d-flex flex-column" ]
        (List.map (\playerScore -> li [class "alert alert-primary"] [ h5 [] [text (playerScore.playerName ++ " got " ++ (String.fromInt playerScore.score ++ " points")) ]]) model.finalScore.score)
    , button [ onClick ReInitGame, class "btn btn-block btn-success" ] [ text "Play again !" ]
    ]

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
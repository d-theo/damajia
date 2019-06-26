port module Main exposing (Model, Msg(..), init, main, receiveMessage, sendMessage, subscriptions, update, view)

import Browser
import Html exposing (Html, button, div, input, li, text, ul, h3, label, h4, b, h5)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode exposing (Decoder, field, string, map4, map3, list, map2, int, map, oneOf, decodeValue, errorToString)
import Json.Encode exposing (Value, object)
import Random
import List.Extra

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
  | GameFinishedView

type alias GameSettings = 
  { name: String
  , timeout: Int
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
    , timeout: Int
    , numberOfQuestions: Int
    , currentQuestion : Maybe GameQuestion
    , currentChoice: Int
    , finalScore: GameScore
    , currentRecap: PlayerRoundRecap
    }

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
    | GameSettingsMsg GameSettingsMsg

type GameSettingsMsg
  = ChangePlayerNameX String
{-| ChangeQuestionNumberX String
  | ChangeTimeoutX String
  | ChangeGameIdX String-}

type alias GameSettingsModel r =
  { r 
    | playerName: String
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
      , timeout = 30
      , numberOfQuestions = -1
      , appConfig = config
      , currentRecap = {playerName= "", answer=-1, goodAnswer=-1, questionId="-"}
      , logs = []
      }
    , Cmd.batch 
      [ Random.generate RandomGameName fiveLetterEnglishWord
      , Random.generate RandomPlayerName fiveLetterEnglishWord
      ]
    )

-- UPDATE
setPlayerName: String -> GameSettingsModel r -> GameSettingsModel r
setPlayerName name game = {game | playerName = name}

updateGameSettings: GameSettingsMsg -> Model -> ( Model, Cmd Msg )
updateGameSettings msg model = 
  case msg of 
    ChangePlayerNameX name ->(setPlayerName name model, Cmd.none )


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
      let 
        gameEvent = parseGameEvent rawEvent
      in 
        case gameEvent of
            NextQuestion question ->
              ({model | currentQuestion = (Just question)}, Cmd.none)
            RoundRecap recap ->
              ({model | currentRecap = (myRecap model.playerName model.currentQuestion recap)}, Cmd.none)
            GameFinished score ->
              ({model | finalScore = score, view = GameFinishedView}, Cmd.none)
            ErrorParse err ->
              ({model | errorMessage = err}, Cmd.none)
            LobbyLog log ->
              ({model | logs = (model.logs ++ [log.info])}, Cmd.none)
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
      (model, (createGame model.appConfig.api_url {name= model.gameId, timeout= model.timeout}))
    JoinGame ->
        ( {model | isJoined = True}
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
        , input [ onInput (GameSettingsMsg << ChangePlayerNameX ), attribute "autocomplete" "off", class "form-control", name "gameid", placeholder "game id", type_ "text", value model.playerName ]
          []
        ]
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
    , button [ onClick JoinGame, class ("btn btn-block " ++ if model.isJoined then "btn-secondary" else "btn-primary"), disabled model.isJoined]
      [ text "join game" ]
    , button [ onClick GameReady, class ("btn btn-block "++if model.isReady then "btn-danger" else if model.isJoined then "btn-success" else "btn-secondary"), disabled (not model.isJoined) ]
      [ text (if model.isReady then "Not Ready" else "Ready") ]
    , ul [ class "d-flex flex-column" ]
        (List.map (\log -> li [] [ h5 [] [text log ]]) model.logs)
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
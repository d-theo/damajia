module Page.Settings exposing (Msg(..), update, Model, view)

import Html exposing (Html, button, div, input, li, text, ul, h3, label, h4, b)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)

type Msg
  = ChangeGameId String
  | ChangeQuestionNumber String
  | CreateGame
  | ChangeTimeout String
  | LobbyToPlayerLobby

type alias Model = 
  { gameId: String
  , timeout: Int
  , numberOfQuestions: Int
  , gameToJoin: String
  }

update : Msg -> Model -> ( Model )
update msg model = case msg of
  ChangeGameId gameId -> { model | gameId = gameId }
  ChangeQuestionNumber nb -> { model | numberOfQuestions = Maybe.withDefault -1 (String.toInt nb) }
  CreateGame -> model  
  ChangeTimeout t -> { model | timeout = Maybe.withDefault -1 (String.toInt t) }
  LobbyToPlayerLobby -> { model | timeout = 10 }

view : Model -> Html Msg
view model =
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
                , input [ onInput ChangeQuestionNumber, attribute "autocomplete" "off", class "form-control", name "newgamenb", type_ "number", value (String.fromInt model.numberOfQuestions) ]
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
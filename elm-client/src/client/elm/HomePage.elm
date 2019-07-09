module HomePage exposing (lobbyView)

import Html exposing (Html, button, div, input, li, text, ul, h3, label, h4, b, h5, span)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Types exposing (Model, Msg(..), GameSettingsMsg(..), GameSettings)

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
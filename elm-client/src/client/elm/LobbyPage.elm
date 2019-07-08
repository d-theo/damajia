module LobbyPage exposing (playerLobbyView)
import Html exposing (Html, button, div, input, li, text, ul, h3, label, h4, b, h5, span)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Types exposing (Model, Msg(..), GameSettingsMsg(..))

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
        (List.map (\log -> li [] [ h5 [style "color" log.color] [text log.text ]]) model.logs)
    , printError model.errorMessage
    ]

printError: String -> Html Msg
printError msg = 
  if String.isEmpty msg then div [class "popup"] [ text msg ]
  else div [class "popup popup--visible"] [ text msg ]
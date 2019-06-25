module Page.Lobby exposing (Msg(..), update, Model, view)

import Html exposing (Html, button, div, input, li, text, ul, h3, label, h4, b)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)

type Msg
  = ChangePlayerName String
  | GameReady
  | JoinGame
  | LobbyToGame

type alias Model = 
  { playerName: String
  }

update : Msg -> Model -> ( Model )
update msg model = case msg of
  ChangePlayerName name -> { model | playerName = name }
  GameReady -> model
  JoinGame -> model
  LobbyToGame -> model

view : Model -> Html Msg
view model =
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
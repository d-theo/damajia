module View exposing (View(..), view)
import Page exposing (Page(..))
import Model exposing (Model)
import Msg exposing (Msg(..))
import Html exposing (Html, text, map)

import Page.Settings as Settings
import Page.Lobby as Lobby

type View 
  = SettingsView (Settings.Model -> Html Settings.Msg)
  | LobbyView (Lobby.Model -> Html Lobby.Msg)

view: Model -> Html Msg
view model = case model.page of
    SettingsPage subModel ->
      Html.map SettingsMsg (Settings.view subModel)
    LobbyPage subMobel ->
      Html.map LobbyMsg (Lobby.view subMobel)
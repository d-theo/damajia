module Page exposing (Page(..))

import Page.Settings as Settings
import Page.Lobby as Lobby

type Page
  = SettingsPage Settings.Model
  | LobbyPage Lobby.Model
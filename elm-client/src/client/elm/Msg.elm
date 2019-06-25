module Msg exposing (Msg(..))
import Json.Encode exposing (Value)

import Page.Settings as Settings
import Page.Lobby as Lobby

type Msg 
  = SettingsMsg Settings.Msg
  | LobbyMsg Lobby.Msg
  | GameEvent Value
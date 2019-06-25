module Update exposing (update)
import Page exposing (Page(..))
import Msg exposing (Msg(..))
import Model exposing (Model)
import Page.Settings as Settings exposing (Msg(..))
import Page.Lobby as Lobby exposing (Msg(..), Model)

update : Msg.Msg -> Model.Model -> ( Model.Model, Cmd Msg.Msg )
update msg ({appConfig, page, global} as model) = case msg of
  SettingsMsg submsg -> 
    case submsg of
      LobbyToPlayerLobby -> 
        ({model | page = LobbyPage { playerName = ""}}, Cmd.none)
      _ ->  
        case model.page of 
          SettingsPage settingsModel -> 
            settingsModel 
              |> Settings.update submsg 
              |> setPage SettingsPage model
              |> withNoCmd
          _ -> (model, Cmd.none)
  GameEvent value -> (model, Cmd.none)
  LobbyMsg submsg -> (model, Cmd.none)

setPage: (subModel -> Page) -> Model.Model -> subModel -> Model.Model
setPage selector model subModel = { model | page = selector subModel }

mapCmd : (a -> b) -> ( model, Cmd a ) -> ( model, Cmd b )
mapCmd f =
    Tuple.mapSecond (Cmd.map f)
withNoCmd : model -> ( model, Cmd msg )
withNoCmd model_ =
    ( model_, Cmd.none )
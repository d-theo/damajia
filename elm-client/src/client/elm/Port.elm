port module Port exposing (subscriptions)
import Model exposing (Model)
import Msg exposing (Msg(..))
import Json.Encode exposing (Value, object)

subscriptions : Model -> Sub Msg
subscriptions model =
    receiveMessage GameEvent


port sendMessage : (String,String) -> Cmd msg

port receiveMessage : (Value -> msg) -> Sub msg
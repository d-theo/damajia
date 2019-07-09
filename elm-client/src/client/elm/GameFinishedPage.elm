module GameFinishedPage exposing (gameFinishedView)
import Html exposing (Html, button, div, input, li, text, ul, h3, label, h4, b, h5, span)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Types exposing (Model, Msg(..))

gameFinishedView: Model -> Html Msg
gameFinishedView model = 
  div []
    [ h4 []
        [ text "Game Finished !" ]
    , ul [ class "d-flex flex-column" ]
        (List.map (\playerScore -> li [class "alert alert-primary"] [ h5 [] [text (playerScore.playerName ++ " got " ++ (String.fromInt playerScore.score ++ " points")) ]]) model.finalScore.score)
    , button [ onClick ReInitGame, class "btn btn-block btn-success" ] [ text "Play again !" ]
    ]
module GamePage exposing (gameView)

import Html exposing (Html, button, div, input, li, text, ul, h3, label, h4, b, h5, span)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http exposing (Error(..))
import Types exposing (Model, Msg(..), View(..), AppConfig, GameSettingsModel, initialModel, TempInGameMessages, GameSettings, GameQuestion, PlayerRoundRecap)

gameView: Model -> Html Msg
gameView model = 
  div []
    [ h4 []
        [ printQuestionTitle model.currentQuestion ]
    , ul [ class "d-flex flex-column" ]
        (printQuestionChoices model model.currentQuestion)
    , displaySmileys
    , displayInGameMessage model.displayedMessages
    , case model.currentQuestion of
      Nothing -> div [] [] 
      Just _ -> 
        String.toInt model.timeout
          |> Maybe.withDefault 1
          |> displayTimer model.timeElapsed
    ]
    
displayFace: String -> String -> String -> String -> Html Msg
displayFace emoji color x y = 
  div [style "position" "fixed", style "top" (x++"%"), style "left" (y++"%")] [div [style "background" color ,class "speech-bubble"]
    [ text emoji
    , span [style "border-top-color" color, class "speech-bubble-sub"] []
    ]]

smiley = ["🤔", "😂", "😃","😭"]

displaySmileys: Html Msg
displaySmileys =
  ul [ class "d-flex smiley" ] (List.map (\smile -> li [onClick (PlayerSendSmiley smile),class "smiley-message"] [text smile] ) smiley)

displayInGameMessage: List TempInGameMessages -> Html Msg
displayInGameMessage messages = 
  ul [ class "d-flex smiley" ] (List.map (\msg -> displayFace msg.text msg.color (String.fromInt msg.top) (String.fromInt msg.left)) messages)

displayTimer: Int -> Int -> Html Msg
displayTimer timeElapsed timeout =
  let
    normalizedTimer = (toFloat timeElapsed / toFloat timeout) * 100
     |> Basics.min 100
  in
    if timeElapsed > 0 then div [class "timer timer-animation", style "width" (String.fromFloat normalizedTimer++"%")] [ ]
    else div [class "timer", style "width" (String.fromFloat normalizedTimer++"%")] [ ]

printQuestionChoices : Model -> Maybe GameQuestion -> List (Html Msg)
printQuestionChoices model question =
  case question of 
    Nothing -> []
    Just q ->
      if q.id == model.currentRecap.questionId then
        (List.map (\choice -> li [class ("answer hoverable alert alert-"++(questionGoodColor choice.id model.currentRecap.answer model.currentRecap.goodAnswer)), onClick (SubmitAnswer choice.id)] ( [text choice.text]++(otherPLayersAnswers model.otherPlayersRecap choice.id))) q.possibleResponses)
      else
        (List.map (\choice -> li [class ("answer hoverable alert "++(colorQuestion choice.id model.currentChoice)), onClick (SubmitAnswer choice.id)] [ text choice.text ]) q.possibleResponses)

printQuestionTitle: Maybe GameQuestion -> Html Msg
printQuestionTitle question =
  case question of
    Nothing -> div [][text "Waiting all players to be ready..."]
    Just q -> text q.title

questionGoodColor: Int -> Int -> Int -> String
questionGoodColor answerId playerChoice goodAnswer = 
  if playerChoice == goodAnswer && answerId == playerChoice then "success"
  else if playerChoice == answerId && answerId /= goodAnswer then "danger"
  else if answerId == goodAnswer then "success"
  else "primary"

colorQuestion: Int -> Int -> String
colorQuestion choiceId selfChoiceId = if choiceId == selfChoiceId then "alert-secondary" else "alert-primary"


otherPLayersAnswers: List PlayerRoundRecap -> Int -> List (Html Msg)
otherPLayersAnswers otherPlayersRecap choiceId = 
  let 
    answers = List.filter (\recap -> recap.answer == choiceId) otherPlayersRecap
  in
    List.indexedMap (\i recap -> span [class "answer-others", style "background-color" recap.color, style "left" (String.fromInt (95-i)++"%")] []) answers
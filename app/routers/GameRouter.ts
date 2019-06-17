import { Inject } from "typescript-ioc";
import { QuizzController } from "../business/quizz/QuizzController";

export class GameRouter {
  @Inject private readonly quizzController: QuizzController;

  join(msg: any) {
    const {playerName, gameId} = msg;
    console.log(`${playerName} joined the game ${gameId}`);
    this.quizzController.addPlayerToGame(gameId, playerName)
  }
  ready(msg: any) {
    const {playerName, gameId, ready} = msg;
    console.log(`${playerName} - ${gameId} is ready : ${ready}`);
    this.quizzController.setPlayerReady(gameId, playerName, ready);
  }
  submit(msg: any) {
    const {playerName, gameId, questionId, answerId} = msg;
    console.log(`${playerName} - ${gameId} is answering question ${questionId} with ${answerId}`);
    this.quizzController.submitAnswer(gameId, playerName, questionId, answerId);
  }
}
import { Inject } from "typescript-ioc";
import { GameController } from "../business/quizz/GameController";

export class GameRouter {
  @Inject private readonly gameController: GameController;

  join(msg: any) {
    const {playerName, gameId} = msg;
    this.gameController.addPlayerToGame(gameId, playerName)
  }
  ready(msg: any) {
    const {playerName, gameId, ready} = msg;
    this.gameController.setPlayerReady(gameId, playerName, ready);
  }
  submit(msg: any) {
    const {playerName, gameId, questionId, answerId} = msg;
    this.gameController.submitAnswer(gameId, playerName, questionId, answerId);
  }
}
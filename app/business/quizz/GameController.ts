import { Quizz } from "../../models/Quizz";
import { Inject, Singleton, AutoWired } from "typescript-ioc";
import { Game } from "./Game";
import { QuizzController } from "./QuizzController";
import { GameRepository } from "../../repository/GameRepository";

@Singleton
@AutoWired
export class GameController {
  @Inject private readonly gameRepository: GameRepository;
  @Inject private readonly quizzController: QuizzController;
  
  constructor() {}

  async createGame() {
    const quizz: Quizz = await this.quizzController.createQuizz();
    const game = new Game(quizz);
    await this.gameRepository.add(game);
    return game;
  }

  async addPlayerToGame(gameId: string, playerName: string) {
    let game: Game = await this.gameRepository.get(gameId);
    if (!game) {
      game = await this.createGame();
    }
    game.getBus().emit('player_joined', {playerName});
  }

  async setPlayerReady(gameId: string, playerName: string, isReady: boolean) {
    const game: Game = await this.gameRepository.get(gameId);
    game.getBus().emit('player_ready', {playerName, isReady});
  }

  async submitAnswer(gameId: string, playerName: string, questionId: string, answerId: number) {
    const game: Game = await this.gameRepository.get(gameId);
    game.getBus().emit('player_answer_question', {playerName, questionId, answerId});
  }
}

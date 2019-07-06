import { Quizz, QuizzSettings } from "../../models/Quizz";
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

  async getById(gameId: string) {
    return await this.gameRepository.get(gameId);
  }

  async createGame(settings: QuizzSettings) {
    const quizz: Quizz = await this.quizzController.createQuizz(settings);
    const game = new Game(quizz);
    await this.gameRepository.add(game);
    return game;
  }

  async addPlayerToGame(gameId: string, playerName: string) {
    try {
      let game: Game = await this.gameRepository.get(gameId);
      console.log(`adding ${playerName} to game id ${gameId}`)
      game.getBus().emit('player_joined', {playerName});
    } catch(e) {
      console.log(e);
    }
  }

  async setPlayerReady(gameId: string, playerName: string, isReady: boolean) {
    const game: Game = await this.gameRepository.get(gameId);
    game.getBus().emit('player_ready', {playerName, isReady});
  }

  async submitAnswer(gameId: string, playerName: string, questionId: string, answerId: number) {
    const game: Game = await this.gameRepository.get(gameId);
    game.getBus().emit('player_answer_question', {playerName, questionId, answerId});
  }

  async ingameMessage(gameId: string, playerName: string, message: string) {
    const game: Game = await this.gameRepository.get(gameId);
    game.getBus().emit('player_ingame_message', {gameId, playerName, message});
  }
}

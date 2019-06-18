import { Quizz } from "../models/Quizz";
import { Singleton, AutoWired } from "typescript-ioc";
import { Game } from "../business/quizz/Game";

@Singleton
@AutoWired
export class GameRepository {
  gameRepo = {};
  constructor() {}
  async add(game: Game) {
    this.gameRepo[game.getQuizz().id] = game;
  }
  async get(id: string) {
    return this.gameRepo[id];
  }
}

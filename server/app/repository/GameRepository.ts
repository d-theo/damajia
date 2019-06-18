import { Quizz } from "../models/Quizz";
import { Singleton, AutoWired } from "typescript-ioc";
import { Game } from "../business/quizz/Game";

@Singleton
@AutoWired
export class GameRepository {
  gameRepo = {};
  constructor() {}
  async add(game: Game) {
    console.log(game);
    console.log(game.getQuizz().id);
    this.gameRepo[game.getQuizz().id] = game;
    console.log(this.gameRepo);
  }
  async get(id: string) {
    console.log(this.gameRepo);
    return this.gameRepo[id];
  }
}

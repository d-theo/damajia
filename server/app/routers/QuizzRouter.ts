import { Path, GET, POST, PathParam } from "typescript-rest";
import { InternalServerError } from "typescript-rest/dist/server/model/errors";
import { Quizz, QuizzSettings } from "../models/Quizz";
import { Inject } from "typescript-ioc";
import { QuizzController } from "../business/quizz/QuizzController";
import { GameController } from "../business/quizz/GameController";
import { Game } from "../business/quizz/Game";

@Path("/quizz")
export class QuizzRouter {
  @Inject private readonly quizzController: QuizzController;
  @Inject private readonly gameController: GameController;

  constructor() {}

  @GET
  @Path(":id")
  async getQuizz(@PathParam("id") id: string): Promise<Quizz> {
    try {
      return await this.quizzController.getQuizz(id);
    } catch (e) {
      throw new InternalServerError(e);
    }
  }

  @POST
  async create(settings: QuizzSettings): Promise<string> {
    try {
      const game: Game = await this.gameController.createGame(settings);
      console.log('created game id ' + game.getQuizz().id);
      return game.getQuizz().id;
    } catch (e) {
      throw new InternalServerError(e);
    }
  }
}
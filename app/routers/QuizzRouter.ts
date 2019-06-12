import { Path, GET, POST, PathParam } from "typescript-rest";
import { InternalServerError } from "typescript-rest/dist/server/model/errors";
import { Quizz } from "../models/Quizz";
import { Inject } from "typescript-ioc";
import { QuizzController } from "../business/quizz/QuizzController";

@Path("/quizz")
export class QuizzRouter {
  @Inject private readonly quizzController: QuizzController;

  constructor() {}

  @GET
  @Path(":id")
  async getQuizz(@PathParam("id") id: string): Promise<Quizz> {
    try {
      console.log(id);
      return await this.quizzController.getQuizz(id);
    } catch (e) {
      throw new InternalServerError(e);
    }
  }

  @POST
  async create(): Promise<string> {
    try {
      return await this.quizzController.createQuizz();
    } catch (e) {
      throw new InternalServerError(e);
    }
  }
}

import { Quizz, QuizzSettings } from "../../models/Quizz";
const uuidv1 = require("uuid/v1");
import { Inject, Singleton, AutoWired } from "typescript-ioc";
import { QuizzRepository } from "../../repository/QuizzRepository";
import { FetchQuizzService } from "../../services/FetchQuizzService";
import { Game } from "./Game";
import { FetchQuizzServiceS3 } from "../../services/FetchQuizzService.s3";

@Singleton
@AutoWired
export class QuizzController {
  @Inject private readonly quizzRepository: QuizzRepository;
  
  constructor() {}

  async createQuizz(settings: QuizzSettings) {
    try {
      const quizz = new Quizz();
      quizz.id = settings.name;
      quizz.timeout = settings.timeout;
      //quizz.questions = await new FetchQuizzService({numberOfQuestions: settings.numberOfquestions}).fetch();
      quizz.questions = await new FetchQuizzServiceS3({numberOfQuestions: settings.numberOfquestions}).fetch();
      await this.quizzRepository.add(quizz);
      return quizz;
    } catch (e) {
      throw new Error("cannot create quizz " + e);
    }
  }

  async getQuizz(id: string) {
    try {
      return await this.quizzRepository.get(id);
    } catch (e) {
      throw new Error("cannot return quizz " + id);
    }
  }

  async listQuizz () {
    try {
      return await this.quizzRepository.list();
    } catch (e) {
      throw new Error("cannot return quizzes ");
    }
  }
}

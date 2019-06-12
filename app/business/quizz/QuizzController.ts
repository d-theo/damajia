import { Quizz } from "../../models/Quizz";
const uuidv1 = require('uuid/v1');
import { Inject, Singleton, AutoWired } from 'typescript-ioc';
import { QuizzRepository } from "../../repository/QuizzRepository";

@Singleton
@AutoWired
export class QuizzController {
  @Inject private readonly quizzRepository: QuizzRepository;
  constructor() {}

  async createQuizz() {
    try {
      const quizzId = uuidv1();
      const quizz = new Quizz();
      quizz.id = quizzId;
      await this.quizzRepository.add(quizz);
      return quizz.id;
    } catch (e) {
      throw new Error('cannot create quizz' + e);
    }
  }

  async getQuizz(id: string) {
    try {
      return await this.quizzRepository.get(id);
    } catch (e) {
      throw new Error('cannot return quizz ' + id);
    }
  }
}
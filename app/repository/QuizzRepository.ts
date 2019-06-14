import { Quizz } from "../models/Quizz";
import { Singleton, AutoWired } from "typescript-ioc";

@Singleton
@AutoWired
export class QuizzRepository {
  quizzRepo = {};
  constructor() {}
  async add(quizz: Quizz) {
    this.quizzRepo[quizz.id] = quizz;
  }
  async get(id: string) {
    return this.quizzRepo[id];
  }
  async save(quizz: Quizz) {
    
  }
}

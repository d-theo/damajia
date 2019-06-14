import { Quizz } from "../models/Quizz";
import { Singleton, AutoWired } from "typescript-ioc";

@Singleton
@AutoWired
export class QuizzRepository {
  quizzRepo = {};
  constructor() {}
  async add(quizz: Quizz) {
    this.quizzRepo[quizz.id] = quizz;
    console.log(this.quizzRepo);
  }
  async get(id: string) {
    console.log(this.quizzRepo[id]);
    return this.quizzRepo[id];
  }
  async save(quizz: Quizz) {
    
  }
}

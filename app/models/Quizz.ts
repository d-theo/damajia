import { PlayerCollection } from "./PlayerCollection";
import { QuestionCollection } from "./QuestionCollection";

export class Quizz {
  id: string;
  startTime: Date;
  players: PlayerCollection;
  questions: QuestionCollection;
  settings: any;
}

import { PlayerCollection } from "./PlayerCollection";
import { QuestionCollection } from "./QuestionCollection";

export class Quizz {
  id: string;
  startTime: Date;
  players: PlayerCollection;
  Questions: QuestionCollection;
  settings: any;
}

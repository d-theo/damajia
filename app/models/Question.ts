import { Answer } from "./Answer";

export class Question {
  id: string;
  title: string;
  possibleResponses: Answer[];
  goodResponse: Answer;
}

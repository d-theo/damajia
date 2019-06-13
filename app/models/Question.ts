import { Answer } from "./Answer";
const uuidv1 = require("uuid/v1");

export class Question {
  id: string;
  title: string;
  possibleResponses: Answer[];
  goodResponse: Answer;
}

export class QuestionBuilder {
  title;
  id = 0;
  answers: Answer[] = [];
  goodResponse: Answer;
  withTitle(title: string): QuestionBuilder {
    this.title = title;
    return this;
  }
  withBadAnswer(answer: string): QuestionBuilder {
    const anAnswer = new Answer();
    anAnswer.id = this.id++;
    anAnswer.text = answer;
    this.answers.push(anAnswer);
    return this;
  }
  withGoodAnswer(answer: string): QuestionBuilder {
    const anAnswer = new Answer();
    anAnswer.id = this.id++;
    anAnswer.text = answer;
    this.answers.push(anAnswer);
    this.goodResponse = anAnswer;
    return this;
  }
  build(): Question {
    const question = new Question();
    question.id = uuidv1();
    question.title = this.title;
    question.possibleResponses = this.answers;
    question.goodResponse = this.goodResponse;
    return question;
  }
}
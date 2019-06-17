import { Question } from "./Question";

export class QuestionCollection {
  questions: Question[] = [];
  playerAnswers: {[questionId: string]: {[playerName: string]: string}} = {};

  get(i: number) {
    if (i >= 0 && i < this.questions.length) {
      return this.questions[i];
    } else {
      return null;
    }
  }

  addPlayerAnswer(playerName, questionId, answerId) {
    if (!this.playerAnswers[questionId]) {
      this.playerAnswers[questionId] = {};
    }

    if (this.playerAnswers[questionId][playerName]) {
      throw new Error('cannot submit twice');
    }

    this.playerAnswers[questionId][playerName] = answerId;
  }

  getRecapOf(questionId: string) {
    return this.playerAnswers[questionId];
  }

  getAnswerOf(questionId: string, playerName: string) {
    if (!this.playerAnswers[questionId]) {
      return null;
    }
    if (!this.playerAnswers[questionId][playerName]) {
      return null;
    }
    return this.playerAnswers[questionId][playerName];
  }
}

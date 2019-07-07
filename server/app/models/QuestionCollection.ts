import { Question } from "./Question";

export class QuestionCollection {
  questions: Question[] = [];
  private playerAnswers: {[questionId: string]: {[playerName: string]: number}} = {};

  get length() {
    return this.questions.length;
  }

  get(i: number) {
    if (i >= 0 && i < this.questions.length) {
      return this.questions[i];
    } else {
      return null;
    }
  }

  getById(id: string): Question | undefined {
    return this.questions.find(q => q.id === id);
  }

  createEmptyAnswer(questionId: string) {
    this.playerAnswers[questionId] = {};
  }

  addPlayerAnswer(playerName: string, questionId: string, answerId: number) {
    if (!this.playerAnswers[questionId]) {
      this.playerAnswers[questionId] = {};
    }

    if (this.playerAnswers[questionId][playerName]) {
      throw new Error('cannot submit twice');
    }

    this.playerAnswers[questionId][playerName] = answerId;
  }

  getRecapOf(questionId: string): QuestionRecap[] {
    const answers = this.playerAnswers[questionId];
    const question = this.getById(questionId);
    if (!question) {
      throw new Error('no question with id ' + questionId)
    }
    return Object.keys(answers).map(playerName => {
      return {
        playerName,
        answer: this.playerAnswers[questionId][playerName],
        goodAnswer: question.goodResponse.id,
        questionId: questionId
      }
    });
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

  numberOfAnswerForQuestion(questionId: string) {
    return Object.keys(this.playerAnswers[questionId]).length;
  }
}

export interface QuestionRecap {
  playerName: string;
  answer: number;
  goodAnswer: number;
  questionId: string;
  color?: string;
}
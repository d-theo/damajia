import { PlayerCollection } from "./PlayerCollection";
import { QuestionCollection } from "./QuestionCollection";
import { Question } from "./Question";

export class Quizz {
  id: string;
  startTime: Date;
  players: PlayerCollection;
  questions: QuestionCollection;
  currentQuestion: Question | null;
  settings: any;
  cptQuestion = 0;

  constructor() {
    this.players = new PlayerCollection();
  }

  nextQuestion() {
    this.currentQuestion = this.questions.get(this.cptQuestion);
    this.cptQuestion++;
  }

  submit(playerName: string, questionId: string, answerId: number) {
    if (!this.currentQuestion) {
      throw new Error('game ended or not initialized');
    }

    if (this.currentQuestion.id !== questionId) {
      throw new Error(playerName+' cannot answer past question '+questionId);
    }

    this.questions.addPlayerAnswer(playerName, questionId, answerId);

    if (this.currentQuestion.goodResponse.id === answerId) {
      this.players.updateScore(playerName, 1);
    }
  }

  getRecapOf(questionId: string) {
    const answers = this.questions.getRecapOf(questionId);
    return {
      answers,
      question: this.currentQuestion
    }
  }

  isStarting() {
    return this.players.areAllReady();
  }
}

import { PlayerCollection, Score } from "./PlayerCollection";
import { QuestionCollection } from "./QuestionCollection";
import { Question } from "./Question";
import { LogCollection } from "./LogCollection";

export class Quizz {
  id: string;
  startTime: Date;
  players: PlayerCollection;
  questions: QuestionCollection;
  currentQuestion: Question | null;
  settings: any;
  cptQuestion = 0;
  isStarted = false;
  isFinished = false;
  timeout = 3;
  logs: LogCollection;
  
  constructor() {
    this.players = new PlayerCollection();
    this.logs = new LogCollection();
  }

  nextQuestion(): Question | null {
    this.currentQuestion = this.questions.get(this.cptQuestion);
    this.cptQuestion++;
    return this.currentQuestion;
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

  getFinalScore(): Score[] {
    return this.players.getScoring();
  }

  canPlayerAnswerTo(playerName: string, questionId: string) {
    if (this.players.get(playerName) === null) {
      return false;
    }
    if (this.questions.getAnswerOf(questionId, playerName) === null) {
      return true;
    }
  }
  everybodyAnswered(questionId: string) {
    const nbResponses = this.questions.numberOfAnswerForQuestion(questionId);
    const nbPlayers = this.players.count();
    return nbPlayers === nbResponses;
  }
}


export interface QuizzSettings {
  name: string;
  timeout: number;
  numberOfquestions: number;
}
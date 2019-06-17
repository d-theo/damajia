import {Quizz} from '../../models/Quizz';
import { Inject } from 'typescript-ioc';
import { Dispatcher } from '../../routers/Dispatcher';

export class Game {
  @Inject private readonly dispatcher: Dispatcher;

  sub;
  constructor(private readonly quizz: Quizz) {
    quizz.startTime = new Date();
    quizz.isStarted = true;
  }

  start() {
    this.sub = setInterval(() => {
      this.quizz.nextQuestion();
      if (this.quizz.currentQuestion == null) {
        this.dispatcher.dispatch(this.quizz, 'game_finished', {
          score: this.quizz.players.getScoring()
        });
        clearInterval(this.sub);
      } else {
        this.dispatcher.dispatch(this.quizz, 'next_question', {
          id: this.quizz.currentQuestion.id,
          title: this.quizz.currentQuestion.title,
          possibleResponses: this.quizz.currentQuestion.possibleResponses
        });
      }
    }, 3000);
  }
}
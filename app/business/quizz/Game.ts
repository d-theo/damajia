import {Quizz} from '../../models/Quizz';
import { Inject } from 'typescript-ioc';
import { Dispatcher } from '../../routers/Dispatcher';
import { GameBus } from './GameBus';
const eventTypes = [
  'timeout',
  'all_answered',
  'next_question',
  'game_end',
  'round_report',
  'game_report',
  'game_start',
  'dispatch_message',
  'player_answer_question',
  'player_ready',
  'player_joined'
];
export class Game {
  @Inject private readonly dispatcher: Dispatcher;
  @Inject private readonly bus: GameBus;

  constructor(private readonly quizz: Quizz) {
   this.bus.on('player_ready', (data: {playerName: string, isReady: boolean}) => {
      if (quizz.isStarted) {
        console.log('game is already started');
        return;
      }
      try {
        quizz.players.setPlayerReady(data.playerName, data.isReady);
        if (quizz.players.areAllReady()) {
          this.bus.emit('game_start', {});
        }
      } catch (e) {
        this.dispatcher.dispatch(quizz, 'error', e);
      }
    });
    this.bus.on('player_joined', (data: {playerName: string}) => {
      try {
        this.quizz.players.addPlayer(data.playerName);
      } catch(e) {
        this.dispatcher.dispatch(quizz, 'error', e);
      }
    });
    this.bus.on('game_start', (data) => {
      if (quizz.isStarted) return;
      quizz.isStarted = true;
      this.bus.emit('next_question', {});
    });
    this.bus.on('timeout', (data: {id: string}) => {
      if (data.id) {
        if (quizz.currentQuestion && quizz.currentQuestion.id !== data.id) {
          console.log('timeout aborted');
          return;
        }
      }
      this.bus.emit('round_report', {});
      this.bus.schedule('next_question', {}, 1);
    });
    this.bus.on('all_answered', (data) => {
      this.bus.emit('round_report', {});
      this.bus.schedule('next_question', {}, 1);
    });
    this.bus.on('next_question', (data) => {
      this.quizz.nextQuestion();
      if (this.quizz.currentQuestion == null) {
        this.bus.emit('game_end', {});
      } else {
        this.dispatcher.dispatch(quizz,'next_question', {
          id: quizz.currentQuestion!.id,
          title: quizz.currentQuestion!.title,
          possibleResponses: quizz.currentQuestion!.possibleResponses
        });

        this.bus.schedule('timeout', {id: quizz.currentQuestion!.id}, quizz.timeout);
      }
    });
    this.bus.on('game_end', (data) => {
      quizz.isFinished = true;
      this.bus.emit('game_report', {});
    });
    this.bus.on('round_report', (data) => {
      this.dispatcher.dispatch(this.quizz, 'round_report', {});
    });
    this.bus.on('game_report', (data) => {
      this.dispatcher.dispatch(this.quizz, 'game_report', {});
    });
    this.bus.on('player_answer_question', (data: {playerName: string,questionId: string,answerId: number}) => {
      try {
        if (! quizz.canPlayerAnswerTo(data.playerName, data.questionId)) {
         throw new Error(data.playerName + ' is not allowed to answer');
        }
        quizz.submit(data.playerName, data.questionId, data.answerId);
        if (quizz.everybodyAnswered(data.questionId)) {
          this.bus.emit('all_answered', {});
        }
      } catch (e) {
        this.dispatcher.dispatch(this.quizz, 'error', e);
      }
    });
  }

  getBus() {
    return this.bus;
  }
  getQuizz() {
    return this.quizz;
  }
}
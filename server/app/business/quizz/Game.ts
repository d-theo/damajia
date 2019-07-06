import {Quizz} from '../../models/Quizz';
import { Inject } from 'typescript-ioc';
import { Dispatcher } from '../../routers/Dispatcher';
import { GameBus } from './GameBus';
import { randomIntFromInterval } from '../../services/utils';

export type GameEvent
  = 'timeout'
  | 'all_answered'
  | 'next_question'
  | 'game_end'
  | 'round_report'
  | 'game_report'
  | 'game_start'
  | 'dispatch_message'
  | 'player_answer_question'
  | 'player_ready'
  | 'player_joined'
  | 'player_ingame_message';

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
        this.quizz.logs.addFromPlayer(quizz.players.get(data.playerName)!, `${data.playerName} is${data.isReady ? " " : " not "}ready`);
        this.dispatcher.dispatch(quizz, 'player_ready', {logs: this.quizz.logs.list()});
        if (quizz.players.areAllReady()) {
          this.bus.emit('game_start', {});
        }
      } catch (e) {
        this.dispatcher.dispatch(quizz, 'error', e);
      }
    });
    this.bus.on('player_joined', (data: {playerName: string}) => {
      try {
        const player = this.quizz.players.addPlayer(data.playerName);
        this.quizz.logs.addFromPlayer(player, `${data.playerName} joined the game`);
        this.dispatcher.dispatch(quizz, 'player_joined', {logs: this.quizz.logs.list()});
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
        if (quizz.isFinished) {
          return;
        }
        if (quizz.currentQuestion && quizz.currentQuestion.id !== data.id) {
          console.log('timeout aborted');
          return;
        }
      }
      this.bus.emit('round_report', {questionId: data.id});
      this.bus.schedule('next_question', {}, 1);
    });
    this.bus.on('all_answered', (data) => {
      this.bus.emit('round_report', {questionId: quizz.currentQuestion!.id});
      this.bus.schedule('next_question', {}, 1);
    });
    this.bus.on('next_question', (data) => {
      const nextQuestion = this.quizz.nextQuestion();
      if (nextQuestion == null) {
        this.bus.emit('game_end', {});
      } else {
        quizz.questions.createEmptyAnswer(nextQuestion.id);
        this.dispatcher.dispatch(quizz,'next_question', {
          id: nextQuestion.id,
          title: nextQuestion.title,
          possibleResponses: nextQuestion.possibleResponses
        });

        this.bus.schedule('timeout', {id: nextQuestion.id}, quizz.timeout);
      }
    });
    this.bus.on('game_end', (data) => {
      quizz.isFinished = true;
      this.bus.emit('game_report', {});
    });
    this.bus.on('round_report', (data) => {
      const report = this.quizz.questions.getRecapOf(data.questionId);
      this.dispatcher.dispatch(this.quizz, 'round_report', report);
    });
    this.bus.on('game_report', (data) => {
      this.dispatcher.dispatch(this.quizz, 'game_report', {score: quizz.getFinalScore()});
    });
    this.bus.on('player_answer_question', ({playerName, questionId, answerId}) => {
      try {
        if (! quizz.canPlayerAnswerTo(playerName, questionId)) {
         throw new Error(playerName + ' is not allowed to answer');
        }
        quizz.submit(playerName, questionId, answerId);
        if (quizz.everybodyAnswered(questionId)) {
          this.bus.emit('all_answered', {});
        }
      } catch (e) {
        this.dispatcher.dispatch(this.quizz, 'error', e);
      }
    });
    this.bus.on('player_ingame_message', ({playerName, message}) => {
      try {
        const player = this.quizz.players.get(playerName)!;
        this.dispatcher.dispatch(this.quizz,'player_ingame_message', {text: message, color: player.color, left:randomIntFromInterval(10,90),top:randomIntFromInterval(10,90)});
      } catch(e) {
        console.log('un intru tente de faire nimp');
      }
    })
  }

  getBus() {
    return this.bus;
  }
  getQuizz() {
    return this.quizz;
  }
}
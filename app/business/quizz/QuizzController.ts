import { Quizz } from "../../models/Quizz";
const uuidv1 = require("uuid/v1");
import { Inject, Singleton, AutoWired } from "typescript-ioc";
import { QuizzRepository } from "../../repository/QuizzRepository";
import { FetchQuizzService } from "../../services/FetchQuizzService";
import { Game } from "./Game";

@Singleton
@AutoWired
export class QuizzController {
  @Inject private readonly quizzRepository: QuizzRepository;
  
  constructor() {}

  async createQuizz() {
    try {
      const quizzId = uuidv1();
      const quizz = new Quizz();
      quizz.id = "test";
      quizz.questions = await new FetchQuizzService({}).fetch();
      await this.quizzRepository.add(quizz);
      return quizz.id;
    } catch (e) {
      throw new Error("cannot create quizz " + e);
    }
  }

  async getQuizz(id: string) {
    try {
      return await this.quizzRepository.get(id);
    } catch (e) {
      throw new Error("cannot return quizz " + id);
    }
  }

  async addPlayerToGame(gameId: string, playerName: string) {
    try { 
      await this.createQuizz();
      const quizz: Quizz = await this.quizzRepository.get(gameId);
      quizz.players.addPlayer(playerName);
      await this.quizzRepository.save(quizz);
    } catch (e) {
      console.log('error' + e);
    }
  }

  async setPlayerReady(gameId: string, playerName: string, isReady: boolean) {
    try { 
      const quizz: Quizz = await this.quizzRepository.get(gameId);
      if (quizz.isStarted) {
        console.log('game is already started');
        return;
      }
      quizz.players.setPlayerReady(playerName, isReady);
      await this.quizzRepository.save(quizz);
      if (quizz.isStarting()) {
        console.log('--- the game '+ quizz.id +' starts ! ---')
        new Game(quizz).start();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      console.log('error' + e);
    }
  }

  async submitAnswer(gameId: string, playerName: string, questionId: string, answerId: number) {
    try { 
      const quizz: Quizz = await this.quizzRepository.get(gameId);
      if (!quizz) {
        throw new Error(gameId + ' does not exists'); 
      }
      if (! quizz.canPlayerAnswerTo(playerName, questionId)) {
       throw new Error(playerName + ' is not allowed to answer');
      }
      
      quizz.submit(playerName, questionId, answerId);
      await this.quizzRepository.save(quizz);
    } catch (e) {
      console.log('error' + e);
    }
  }

  async getRoundRecap(gameId: string, questionId: string) {
    const quizz: Quizz = await this.quizzRepository.get(gameId);
    return quizz.getRecapOf(questionId);
  }
}

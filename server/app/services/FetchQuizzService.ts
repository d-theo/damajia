import { QuestionBuilder, Question } from "../models/Question";
import { QuestionCollection } from "../models/QuestionCollection";
import * as _ from 'lodash';
import { mapObject, atob } from "./utils";

const axios = require('axios');

export class FetchQuizzService {
  amount: number;
  constructor(params: any) {
    this.amount = params.numberOfQuestions;
  }

  async fetch(): Promise<QuestionCollection> {
    const url = `https://opentdb.com/api.php?category=9&amount=${this.amount}&type=multiple&encode=base64`;
    const mapper = mapObject((questionAPI: QuestionAPI) => {
      const builder = new QuestionBuilder().withTitle(atob(questionAPI.question));
      for (let incorrect of questionAPI.incorrect_answers) {
        builder.withBadAnswer(atob(incorrect));
      }
      return builder
        .withGoodAnswer(atob(questionAPI.correct_answer))
        .build();
    });

    const apiRes = await axios.get(url);
    const questions: Question[] = (apiRes.data as QuizzApi).results.map(questionApi => mapper(questionApi));
    const questionCollection = new QuestionCollection();
    questionCollection.questions = questions;
    return questionCollection;
  }
}

interface QuizzApi {
  response_code: 0;
  results: QuestionAPI[];
}

interface QuestionAPI {
  category: string;
  type: string;
  difficulty: string;
  question: string;
  correct_answer: string;
  incorrect_answers: string[];
}
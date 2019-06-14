import { QuestionBuilder, Question } from "../models/Question";
import { QuestionCollection } from "../models/QuestionCollection";
import * as _ from 'lodash';

const axios = require('axios');

export class FetchQuizzService {
  amount: number;
  category: number;
  difficulty: "medium" | "easy" | "hard";
  type: "multiple" | "boolean";
  categoryMap = {
    9: "",
    10: "",
    11: "",
    12: "",
    13: "",
    14: "",
    15: "",
    16: "",
    17: "",
    18: "",
    19: "",
    20: "",
    21: "",
    22: "",
    23: "",
    24: "",
    25: "",
    26: "",
    27: "",
    28: "",
    29: "",
    30: "",
    31: "",
    32: ""
  };
  constructor(params: any) {}

  async fetch(): Promise<QuestionCollection> {
    /*const amount = 10;
    const category = 9;
    const difficulty = "medium";
    const type = "multiple";
    const url `https://opentdb.com/api.php?amount=${amount}&category=${category}&type=${type}&difficulty=${difficulty}`;*/
    const url = "https://opentdb.com/api.php?amount=10&type=multiple&encode=base64";
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
    const questions: Question[] = apiRes.data.results.map(questionApi => mapper(questionApi));
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

export function mapObject<T,R>(mapper: (o: T) => R) {
  return (obj: T) => {
    return mapper(obj);
  }
}

function atob(b64) {
  return Buffer.from(b64, 'base64').toString();
}
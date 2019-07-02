import { QuestionBuilder, Question } from "../models/Question";
import { QuestionCollection } from "../models/QuestionCollection";
import * as _ from 'lodash';
import { mapObject } from "./utils";

const axios = require('axios');

export class FetchQuizzServiceS3 {
  amount: number;

  constructor(params: any) {
    this.amount = params.numberOfQuestions;
  }

  async fetch(): Promise<QuestionCollection> {
    const url = `https://grulitoworld.s3-eu-west-1.amazonaws.com/damajia/all.json`;
    const mapper = mapObject((questionAPI: QuestionAPI) => {
      const builder = new QuestionBuilder().withTitle(questionAPI.question);
      for (let incorrect of questionAPI.incorrect_answers) {
        builder.withBadAnswer(incorrect);
      }
      return builder
        .withGoodAnswer(questionAPI.correct_answer)
        .build();
    });

    const apiRes = await axios.get(url);
    const questions: Question[] = (apiRes.data as S3QuizzApi).quizz.map(questionApi => mapper(questionApi));
    const questionCollection = new QuestionCollection();
    questionCollection.questions = _.sampleSize(questions, this.amount);
    return questionCollection;
  }
}

interface S3QuizzApi {
  quizz: QuestionAPI[];
}

interface QuestionAPI {
  category: string;
  type: string;
  difficulty: string;
  question: string;
  correct_answer: string;
  incorrect_answers: string[];
}
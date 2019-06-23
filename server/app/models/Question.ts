import { Answer } from "./Answer";
const uuidv1 = require("uuid/v1");

export class Question {
  id: string;
  title: string;
  possibleResponses: Answer[];
  goodResponse: Answer;
}

export class QuestionBuilder {
  title;
  answers: Answer[] = [];
  goodResponse: Answer;
  id = 0;
  withTitle(title: string): QuestionBuilder {
    this.title = title;
    return this;
  }
  withBadAnswer(answer: string): QuestionBuilder {
    const anAnswer = new Answer();
    anAnswer.text = answer;
    anAnswer.id = this.id++;
    this.answers.push(anAnswer);
    return this;
  }
  withGoodAnswer(answer: string): QuestionBuilder {
    const anAnswer = new Answer();
    anAnswer.text = answer;
    anAnswer.id = this.id++;
    this.goodResponse = anAnswer;
    return this;
  }
  build(): Question {
    const question = new Question();
    question.id = uuidv1();
    question.title = this.title;
    this.answers.push(this.goodResponse);
    this.answers = this.shuffle(this.answers);

    let ids: number[] = [];
    for (let i = 0; i < this.answers.length; i++) {
      ids.push(i);
    }
    ids = this.shuffle(ids);
    console.log(ids);
    this.answers.forEach(q => {
        q.id = ids.pop() || 0;
    });
    
    question.possibleResponses = this.answers;
    question.goodResponse = this.goodResponse;
    return question;
  }

  shuffle(array) {
    let counter = array.length;

    // While there are elements in the array
    while (counter > 0) {
        // Pick a random index
        let index = Math.floor(Math.random() * counter);

        // Decrease counter by 1
        counter--;

        // And swap the last element with it
        let temp = array[counter];
        array[counter] = array[index];
        array[index] = temp;
    }

    return array;
  }
}

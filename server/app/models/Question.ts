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
    this.answers.push(anAnswer);
    this.goodResponse = anAnswer;
    return this;
  }
  build(): Question {
    const question = new Question();
    question.id = uuidv1();
    question.title = this.title;
    this.answers = this.shuffle(this.answers);
    const ids = this.shuffle([...Array(this.answers.length)].map((_, i) => i));
    this.answers.forEach(q => {
      if (this.goodResponse.id === q.id) {
        const newId = ids.pop();
        this.goodResponse.id = newId;
        q.id = newId;
      } else {
        q.id = ids.pop();
      }
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

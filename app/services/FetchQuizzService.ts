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

  async fetch() {
    const amount = 10;
    const category = 9;
    const difficulty = "medium";
    const type = "multiple";
    //const url `https://opentdb.com/api.php?amount=${amount}&category=${category}&type=${type}&difficulty=${difficulty}`;
    const url = "https://opentdb.com/api.php?amount=10&type=multiple";
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

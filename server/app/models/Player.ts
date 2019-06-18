export class Player {
  name: string;
  score: number;
  isReady: boolean;
  constructor(name: string) {
    this.name = name;
    this.isReady = false;
    this.score = 0;
  }
}

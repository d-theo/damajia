export class Player {
  name: string;
  score: number;
  isReady: boolean;
  color: string;
  constructor(name: string) {
    this.name = name;
    this.isReady = false;
    this.score = 0;
    this.color = `hsla(${Math.random() * 360}, 100%, 50%, 1)`
  }
}

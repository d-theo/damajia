import { Player } from "./Player";

export class PlayerCollection {
  private players: { [name: string]: Player; } = {} 
  
  addPlayer(playerName: string) {
    if (this.players[playerName]) {
      throw new Error('player name already exists');
    } else {
      this.players[playerName] = new Player(playerName);
    }
  }
  setPlayerReady(playerName: string, isReady: boolean) {
    if (!this.players[playerName]) {
      throw new Error('no player '+playerName);
    }
    this.players[playerName].isReady = isReady;
  }
  updateScore(playerName: string, score: number) {
    if (!this.players[playerName]) {
      throw new Error('no player can score '+playerName);
    }
    this.players[playerName].score += score;
  }

  areAllReady() {
    for (const pid in this.players) {
      if (!this.players[pid].isReady) {
        return false;
      }
    }
    return true;
  }

  get(playerName: string) {
    if (this.players[playerName]) {
      return this.players[playerName];
    } else {
      return null;
    }
  }

  list() {
    return Object.values(this.players);
  }

  getScoring (): Score[] {
    const score: Score[] = [];
    for (const pid in this.players) {
      score.push({
        playerName: this.players[pid].name,
        score: this.players[pid].score
      });
    }
    return score;
  }

  count() {
    return Object.keys(this.players).length;
  }
}

export interface Score {
  playerName: string;
  score: number;
}
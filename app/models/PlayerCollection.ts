import { Player } from "./Player";

export class PlayerCollection {
  players: any = {};
  
  addPlayer(playerName: string) {
    if (this.players[playerName]) {
      return;
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
}

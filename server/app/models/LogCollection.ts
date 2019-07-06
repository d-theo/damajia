import { Log } from "./Log";
import { Player } from "./Player";

export class LogCollection {
  logs: Log[] = [];
  addFromPlayer(player: Player, text: string) {
    this.logs.push({
      color: player.color,
      text
    })
  }
  list() {
    return this.logs;
  }
}
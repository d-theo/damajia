import { GameEvent } from "./Game";

export class GameBus {
  subs = {};
  constructor() {}
  on(eventName: GameEvent, func: ((data: any) => (void))) {
    if (this.subs[eventName] === undefined) {
      this.subs[eventName] = [];
    }

    this.subs[eventName].push(func);
  }
  emit(eventName: GameEvent, data: any) {
    console.log(eventName, data);
    if (!this.subs[eventName]) return;

    this.subs[eventName].forEach(fun => {
      fun(data);
    })
  }
  schedule(eventName: GameEvent, data: any, delaySecond: number) {
    setTimeout(() => {
      this.emit(eventName, data);
    }, delaySecond * 1000);
  }
}
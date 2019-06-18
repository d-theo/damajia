export class GameBus {
  subs = {};
  constructor() {}
  on(eventName: string, func: ((data: any) => (void))) {
    if (this.subs[eventName] === undefined) {
      this.subs[eventName] = [];
    }

    this.subs[eventName].push(func);
  }
  emit(eventName, data: any) {
    console.log(eventName, data);
    if (!this.subs[eventName]) return;

    this.subs[eventName].forEach(fun => {
      fun(data);
    })
  }
  schedule(eventName, data, delaySecond) {
    setTimeout(() => {
      this.emit(eventName, data);
    }, delaySecond * 1000);
  }
}
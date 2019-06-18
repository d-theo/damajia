import { WSServer } from "../WSServer";
import { Quizz } from "../models/Quizz";
import { AutoWired, Singleton } from "typescript-ioc";

@Singleton
@AutoWired
export class Dispatcher {
  wsServer: WSServer;
  constructor() {}
  dispatch(quizz: Quizz, event: string, message: any) {
    console.log(quizz.id + " " + event + " " + JSON.stringify(message));
    this.wsServer.sendMessage(quizz.id, event, message);
  }
}
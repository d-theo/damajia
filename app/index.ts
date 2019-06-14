
import {Configuration} from "./Configuration";
import {Container, Provider} from 'typescript-ioc';
import {HttpServer} from "./HttpServer";
import { WSServer } from "./WSServer";
import { Dispatcher } from "./routers/Dispatcher";

start();

async function start() {
  try {
    const config: Configuration = Container.get(Configuration);
    await config.init();

    const httpServer = new HttpServer(config);
    await httpServer.start();

    const wsServer = new WSServer();
    await wsServer.start();

    const messageDispatcher: Dispatcher = Container.get(Dispatcher);
    messageDispatcher.wsServer = wsServer;

    //Routine de shutdown
    process.on("SIGINT", async () => {
      try {
        process.exit(0);
      } catch (e) {
        process.exit(1);
      }
    });
  } catch (e) {
    console.error(`ERROR: Worker failed to initialize: ${e}`);
    process.exit(1);
  }
}

import {Configuration} from "./Configuration";
import {Container, Provider} from 'typescript-ioc';
import {HttpServer} from "./HttpServer";

start();

async function start() {
  try {
    const config: Configuration = Container.get(Configuration);
    await config.init();

    const httpServer = new HttpServer(config);
    await httpServer.start();

    const http = require('http').createServer(httpServer.getApp());
    const io = require('socket.io')(http);
    io.on('connection', function(socket){
      console.log('a user connected');
      socket.on('join', msg => {
        socket.join('room1');
        // get quizz, add player
      });
      socket.on('ready', msg => {
        // get quizz, rdy player, if all ready, launch game
      });
      socket.on('submit', msg => {
        // get quizz, tell answer
      });
      //io.to('some room').emit('some event', 'msg');
    });

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
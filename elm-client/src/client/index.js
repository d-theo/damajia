import './index.html';
import './styles.css';
import './bootstrap.min.css';
import { Elm } from './elm/Main.elm';

let serverUrl;
let wsPort = 3000;
let apiPort = 3001;
if (process.env.NODE_ENV === 'production') {
  serverUrl = 'http://damajia.grulitoworld.co';
} else {
  serverUrl = 'http://127.0.0.1';
}
const app = Elm.Main.init({
  node: document.getElementById('elm'),
  flags: {
    api_url: serverUrl+':'+apiPort
  }
});
const socket = io(serverUrl+':'+wsPort);
app.ports.sendMessage.subscribe(function(message) {
  const msg = message[1].split(',');
  switch (message[0]) {
    case 'join':
      socket.emit(message[0], {
        playerName: msg[0],
        gameId: msg[1],
      });
      break;
    case 'ready':
        socket.emit(message[0], {
          playerName: msg[0],
          gameId: msg[1],
          ready: msg[2] === 'true' ? true : false ,
        });
      break;
    case 'submit':
        socket.emit(message[0], {
          playerName: msg[0],
          gameId: msg[1],
          questionId: msg[2],
          answerId: parseInt(msg[3], 10)
        });
    case 'player_ingame_message':
      socket.emit(message[0], {
        playerName: msg[0],
        gameId: msg[1],
        message: msg[2],
      });    
      break;
  }
});
socket.on('next_question', function(message) {
  console.log('next_question');
  app.ports.receiveMessage.send(message);
});
socket.on('round_report', function(message) {
  console.log('round_report');
  app.ports.receiveMessage.send(message);
});
socket.on('game_report', function(message) {
  console.log('game_report', message);
  app.ports.receiveMessage.send(message);
});
socket.on('player_ready', function(message) {
  console.log('player_ready', message);
  app.ports.receiveMessage.send(message);
});
socket.on('player_joined', function(message) {
  console.log('player_joined', message);
  app.ports.receiveMessage.send(message);
});
socket.on('player_ingame_message', function(message) {
  console.log('player_ingame_message', message);
  app.ports.receiveMessage.send(message);
});

import './index.html';
import './styles.css';

import { Elm } from './elm/Main.elm';

const app = Elm.Main.init({
  node: document.getElementById('elm')
});
const socket = io('http://127.0.0.1:3000');
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
      break;
  }
});
socket.on('next_question', function(message) {
  console.log(message);
  app.ports.receiveMessage.send(message);
});
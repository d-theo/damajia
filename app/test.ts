function testSocket()
    {
        var socket = require('socket.io-client')('http://127.0.0.1:3000', {rejectUnauthorized: false });
        socket.on('test', onMessage );
        socket.on('connect', onConnect );
        socket.on('disconnect', onDisconnect );
        socket.on('connect_error', onError );
        socket.on('reconnect_error', onError );
        socket.on('game_finished', onMessage );
        socket.on('next_question', onMessage );
        function onConnect(evt)
        {
            writeToScreen("CONNECTED");
            doSend('join',{
              playerName: "theo",
              gameId: "test"
            });
            setTimeout(() => {
              doSend('ready',{
                playerName: "theo",
                gameId: "test",
                ready: true
              });
            }, 2000)
        }
        function onDisconnect(evt)
        {
            writeToScreen("DISCONNECTED");
        }
        function onMessage(data)
        {
            writeToScreen('<span style="color: blue;">RESPONSE: ' + JSON.stringify(data)+'</span>');
            doSend('submit',{
              playerName: "theo",
              gameId: "test",
              questionId: data.question.id,
              answerId: 3
            });
        }
        function onError(message)
        {
            writeToScreen('<span style="color: red;">ERROR:</span> ' + message);
        }
        function doSend(evt, message)
        {
            writeToScreen("SENT: " + message);
            socket.emit(evt, message);
        }
        function writeToScreen(message)
        {
			    console.log(message);
        }
    }
testSocket();

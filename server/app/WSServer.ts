import express from 'express';
import {Server} from "typescript-rest";
import {Configuration} from "./Configuration";
import compression from 'compression';
import * as cors from 'cors';
import * as BodyParser from 'body-parser';
import { QuizzRouter } from './routers/QuizzRouter';
import { GameRouter } from './routers/GameRouter';

export class WSServer {
	private readonly port = 3000;
  private readonly app;
  private readonly io;
  private readonly router = new GameRouter();
	constructor() {
    const server = require('http').createServer();
    const io = require('socket.io')(server);
    this.app = server;
    this.io = io;
    io.on('connection', socket => {
      console.log('a user connected');
      socket.on('join', msg => {
        socket.join(msg.gameId);
        this.router.join(msg);
      });
      socket.on('ready', msg => {
        this.router.ready(msg);
      });
      socket.on('submit', msg => {
        this.router.submit(msg);
      });
      socket.on('player_ingame_message', msg => {
        this.router.ingameMessage(msg);
      });
    });
  }

  sendMessage(room, event, message) {
    this.io.to(room).emit(event, message);
  }

	start() {
		return new Promise((resolve, reject) => {
			this.app.listen(this.port, () => {
				console.log(`wss running and listening on port ${this.port}`);
				resolve();
			});
		});
	}
}
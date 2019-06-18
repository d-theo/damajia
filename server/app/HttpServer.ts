import express from 'express';
import {Server} from "typescript-rest";
import {Configuration} from "./Configuration";
import compression from 'compression';
import * as cors from 'cors';
import * as BodyParser from 'body-parser';
import { QuizzRouter } from './routers/QuizzRouter';

export class HttpServer {
	private readonly app: express.Application;
	private readonly port = 3001;

	constructor(config: Configuration) {
		this.app = express();
		this.app.use(compression());
		this.app.use(cors.default());

		//Parser type JSON pour les payloads en POST
		this.app.use(BodyParser.json());

		Server.buildServices(
      this.app,
      QuizzRouter
		);
  }
  
  getApp() {
    return this.app;
  }

	start() {
		return new Promise((resolve, reject) => {
			this.app.listen(this.port, () => {
				console.log(`Quizz Backend running and listening on port ${this.port}`);
				resolve();
			});
		});
	}
}

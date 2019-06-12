
import * as moment from 'moment';
import {Configuration} from "./Configuration";
import {Container, Provider} from 'typescript-ioc';
import {HttpServer} from "./HttpServer";

start();

async function start() {
    try {
        const config : Configuration = Container.get(Configuration);
        await config.init();
        
        const httpServer = new HttpServer(config);
		    await httpServer.start();

        //Routine de shutdown
        process.on('SIGINT', async () => {
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
#!bin/bash

yarn init -y

mkdir routes controllers models middleware constants helpers config

for folder in $(ls -d */)
do
    touch $folder/index.js
    
done

yarn add express dotenv mongoose helmet esm  cors
yarn add -D morgan eslint

touch server.js index.js



#index.js
echo "

    // eslint-disable-next-line no-global-assign
    require = require('esm').module();
    module.exports = require('./server.js');
" >> index.js

#server.js
echo 'import { HttpServer, envVariables, dbConnection } from "./config";
import { defaultMiddleware, errorHandler } from "./middleware";
import {testRouter} from "./routes";

const { port, uri } = envVariables;
const main = () => {
  const server = new HttpServer();
  server.applyHandleRequestMiddleware(defaultMiddleware);
  dbConnection(uri);
  server.applyRouter(testRouter);
  server.applyHandleResponseMiddleware(errorHandler);
  server.initialize(port);
};

main();
' >> server.js

#middleware
touch middleware/errorHandler.js  middleware/defaultMiddleware.js

echo 'import { HttpError } from "../constants";

export const errorHandler = (server) => {
  server.use((req, res, next) => {
    const err = new HttpError("Not found", 404);
    next(err);
  });

  server.use((err, req, res, next) => {
    const error =
      server.get("env") !== "production"
        ? err
        : {
            message: "Server error",
            status: 500,
          };
    return res.status(error.status).json(error);
  });
};
' >> middleware/errorHandler.js

echo '
import helmet from "helmet";
import { json } from "express";
import cors from "cors";

export const defaultMiddleware = (server) => {
  const morgan = server.get("env") !== "production" ? require("morgan") : null;
  if (morgan) server.use(morgan("dev"));
  server.use(json());
  server.use(cors());
  server.use(helmet());
};

' >> middleware/defaultMiddleware.js

echo '
import { defaultMiddleware } from "./defaultMiddleware";
import { errorHandler } from "./errorHandler";

export { defaultMiddleware, errorHandler };
' >> middleware/index.js

#constants
touch constants/HttpError.js
echo 'export class HttpError extends Error {
  constructor(message, status) {
    super(message);
    this.status = status;
  }
}
' >> constants/HttpError.js

echo 'import { HttpError } from "./HttpError";

export { HttpError };
' >> constants/index.js

#config
touch config/env.js config/server.config.js config/db.config.js

echo 'import express from "express";

export class HttpServer {
  constructor() {
    this.server = express();
  }
  initialize(port) {
    this.server.listen(port, () =>
      console.log(`server is listening on port: ${port}.`)
    );
  }
  applyHandleRequestMiddleware(middleware) {
    middleware(this.server)
  }
  applyRouter(router) {
      this.server.use(router);
  }
  applyHandleResponseMiddleware(middleware) {
      middleware(this.server)
  }
}
' >> config/server.config.js

echo 'import { envVariables } from "./env";
import { HttpServer } from "./server.config";
import {dbConnection} from "./db.config";

export { envVariables, HttpServer, dbConnection };
' >> config/index.js

echo 'require("dotenv").config();

const port = process.env.PORT || 3000;
const uri = process.env.DB_URI || "mongodb://localhost:27017/test";

export const envVariables = {
    port,
    uri,

}' >> config/env.js

echo 'import mongoose from "mongoose";

export const dbConnection = (uri) => {
  mongoose.connect(uri, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  });
  const db = mongoose.connection;
  db.once("open", () => console.log("connected to database"));
};
' >> config/db.config.js

#routes
touch routes/testRouter.js

echo '
import {Router} from "express";
import {testController} from "../controllers";

const {getIndex} = testController;
export const testRouter = Router();

testRouter.route("/").get(getIndex);


' >> routes/testRouter.js

echo '
import {testRouter} from "./testRouter";

export {testRouter}

' >> routes/index.js

#controllers

touch controllers/testController.js

echo '

const getIndex = async (req,res,next) =>{
    return res.status(200).json({message: "OK"});

}

export const testController = {getIndex};
' >> controllers/testController.js

echo '
import {testController} from "./testController";

export {testController}

' >> controllers/index.js

#eslint
./node_modules/.bin/eslint --init

#create .env and readme
echo '

### Add to package.json
```
 "scripts": {
  "start": "node -r esm server.js",
  "dev": "nodemon -r esm server.js"
},
```
' >> readme.md
touch .env

#add to git
touch .gitignore
echo '
node_modules
yarn.lock
npm.lock' >> .gitignore

#git
git init
git add .
git commit -m "initialize server"

echo 'Happy coding!!!'
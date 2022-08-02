import Score from "./score";
import { Sequelize } from 'sequelize-typescript';

// NOTE: right now we have the following problem, but as we are using `toJSON`
//       in our API we are not directly affected:
//       https://github.com/sequelize/sequelize-typescript/issues/778

let uri = process.env.DB_URI || ""; // setting URI directly can be used to also use SQLite
const username = process.env.DB_USERNAME || "";
const password = process.env.DB_PASSWORD || "";
const host = process.env.DB_HOST || "";
const port = process.env.DB_PORT || "";
const database = process.env.DB_DATABASE || "";
const socket = process.env.DB_SOCKET || "";
if (host !== "") { // If host is specified let's construct a URI
    uri = "postgres://" + username + (password !== "" ? ":" + password : "") + "@" + encodeURIComponent(host) + (port !== "" ? ":" + port : "") + "/" + database;
}

const logging = process.env.NODE_ENV === 'production' ? false : console.log

const sequelize = (uri !== "" ?
    new Sequelize(uri, { logging }) :
    new Sequelize(database, username, password, {
        dialect: "postgres",
        host: socket,
        dialectOptions: {
            socketPath: socket
        },
        logging
    })
);

sequelize.addModels([Score]);

await sequelize.sync({ alter: process.env.NODE_ENV === 'development' })

export {
    sequelize,
    Score,
};

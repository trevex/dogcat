import Score from "./score";
import { Sequelize } from 'sequelize-typescript';

// NOTE: right now we have the following problem, but as we are using `toJSON`
//       in our API we are not directly affected:
//       https://github.com/sequelize/sequelize-typescript/issues/778

let uri = process.env.DB_URI || "";
if (uri === "") {
    const dialect = process.env.DB_DIALECT || "";
    const username = process.env.DB_USERNAME || "";
    const password = process.env.DB_PASSWORD || "";
    const host = process.env.DB_HOST || "";
    const port = process.env.DB_PORT || "";
    const database = process.env.DB_DATABASE || "";
    if (dialect !== "") { // A dialect is specifed and uri not, so let's construct it ourselves
        uri = dialect + "://" + username + (password !== "" ? ":" + password : "") + "@" + host + (port !== "" ? ":" + port : "") + "/" + database;
    }
}

const sequelize = new Sequelize(process.env.DB_URI || "", {
    logging: process.env.NODE_ENV === 'production' ? false : console.log
});

sequelize.addModels([Score]);

await sequelize.sync({ alter: process.env.NODE_ENV === 'development' })

export {
    sequelize,
    Score,
};

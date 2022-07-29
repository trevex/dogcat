import Score from "./score";
import { Sequelize } from 'sequelize-typescript';

// NOTE: right now we have the following problem, but as we are using `toJSON`
//       in our API we are not directly affected:
//       https://github.com/sequelize/sequelize-typescript/issues/778

const sequelize = new Sequelize(process.env.DB_URI || "", {
    logging: process.env.NODE_ENV === 'production' ? false : console.log
});

sequelize.addModels([Score]);

await sequelize.sync({ alter: process.env.NODE_ENV === 'development' })

export {
    sequelize,
    Score,
};

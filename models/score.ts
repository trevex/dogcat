import db from "./db";
import { DataTypes } from 'sequelize';

const Score = db.define('Score', {
    username: DataTypes.STRING,
    datetime: DataTypes.DATE,
    value: DataTypes.NUMBER,
});

await Score.sync();

export default Score;

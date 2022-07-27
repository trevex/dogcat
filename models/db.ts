import { Sequelize, Model, DataTypes } from 'sequelize';

const sequelize = new Sequelize(process.env.DB_URI);

export default sequelize

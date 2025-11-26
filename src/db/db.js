// import { Sequelize } from "sequelize";

// //ORM
// const sequelize = new Sequelize(process.env.DATABASE_URL,{
//     dialect: 'postgres',

// })

// export default sequelize;


import { Sequelize } from "sequelize";
import dotenv from "dotenv";

dotenv.config({ path: "./.env" }); // Load environment variables early

// Initialize Sequelize ORM
const sequelize = new Sequelize(process.env.DATABASE_URL, {
  dialect: "postgres",
  dialectOptions: {
    ssl: {
      require: true,
      rejectUnauthorized: false,
    },
  },
  logging: false,
});

export default sequelize;

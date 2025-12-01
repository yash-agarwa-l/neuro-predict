import dotenv from "dotenv";
dotenv.config({ path: "./.env" });

import app from "./app.js";
import sequelize from "./db/db.js";

sequelize
  .sync() 
  .then(() => {
    console.log("Connected to Postgres");

    app.listen(process.env.PORT || 3000, () => {
      console.log(`Server running on port ${process.env.PORT || 8080}`);
    });
  })
  .catch((err) => {
    console.error("Failed to connect to Postgres:", err);
  });

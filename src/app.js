import express from "express";
import {authRouter, predictionRouter, adminRouter} from "./routes/routes.js";
import cors from "cors";
const app = express();

app.use(express.json());
app.use(cors());
app.use("/auth",authRouter);
app.use("/predictions",predictionRouter);
app.use("/admin",adminRouter)

export default app;
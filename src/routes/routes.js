import express from 'express';
import * as authController from '../controllers/auth.controller.js';
import * as predictionController from '../controllers/prediction.controller.js';
import * as adminController from '../controllers/admin.controller.js';

import { verifyJwt } from '../middlewares/jwt.middleware.js';
import { isAdmin } from '../middlewares/admin.middleware.js';

// Auth Routes
export const authRouter = express.Router();
authRouter.post('/signin', authController.signin);
authRouter.post('/login', authController.login);
authRouter.post('/refresh', authController.refreshAccessToken);

// Prediction Routes
export const predictionRouter = express.Router();
predictionRouter.post('/add', verifyJwt, predictionController.addPrediction);
predictionRouter.get('/history', verifyJwt, predictionController.getUserPredictions);

predictionRouter.post('/report', verifyJwt, predictionController.downloadReport);

// Admin Routes
export const adminRouter = express.Router();
adminRouter.get('/users', verifyJwt, isAdmin, adminController.getAllUsers);
adminRouter.get('/predictions', verifyJwt, isAdmin, adminController.getAllPredictions);
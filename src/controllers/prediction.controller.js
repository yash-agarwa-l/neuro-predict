import db from '../models/index.js';
import { ApiResponse } from '../utils/api.response.js';

/**
 * @description Add a new prediction log for the logged-in user
 * @route POST /api/v1/predictions/add
 * @access Private
 */
export const addPrediction = async (req, res) => {
    // A transaction is crucial here to ensure data integrity
    const transaction = await db.sequelize.transaction();
    try {
        // We get the user ID from the 'req.user' object,
        // which is added by your authentication middleware (e.g., jwtVerify)
        const userId = req.user?.id;

        if (!userId) {
            await transaction.rollback();
            return res.status(401).json(new ApiResponse(401, "Unauthorized: User not logged in"));
        }

        // All the input and output data comes from the request body
        const predictionData = req.body;

        // You can add more robust validation here if needed
        if (!predictionData.sleep_stage || !predictionData.alzheimer_risk_score) {
             await transaction.rollback();
            return res.status(400).json(new ApiResponse(400, "Bad Request: Missing required prediction fields"));
        }

        // Create the new prediction log, associating it with the user
        const newLog = await db.PredictionLog.create({
            ...predictionData,
            user_id: userId 
        }, { transaction });

        // If everything is successful, commit the transaction
        await transaction.commit();

        return res.status(201).json(new ApiResponse(
            201,
            "Prediction log saved successfully",
            newLog
        ));

    } catch (e) {
        // If any error occurs, roll back the entire transaction
        await transaction.rollback();
        console.error('Add Prediction error:', e);
        return res.status(500).json(new ApiResponse(
            500,
            "Internal Server Error",
            e.message
        ));
    }
};

/**
 * @description Get all prediction logs for the currently logged-in user
 * @route GET /api/v1/predictions/history
 * @access Private
 */
export const getUserPredictions = async (req, res) => {
    try {
        const userId = req.user?.id;

        if (!userId) {
            return res.status(401).json(new ApiResponse(401, "Unauthorized: User not logged in"));
        }

        // Find all logs where the user_id matches the logged-in user
        // We can sort them by creation date to get the newest first
        const predictions = await db.PredictionLog.findAll({
            where: { user_id: userId },
            order: [['created_at', 'DESC']]
        });

        if (!predictions) {
            // This isn't an error, just no data
            return res.status(200).json(new ApiResponse(200, "No prediction history found", []));
        }

        return res.status(200).json(new ApiResponse(
            200,
            "Prediction history retrieved successfully",
            predictions
        ));

    } catch (e) {
        console.error('Get User Predictions error:', e);
        return res.status(500).json(new ApiResponse(
            500,
            "Internal Server Error",
            e.message
        ));
    }
};
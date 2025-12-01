import { Transaction } from 'sequelize';
import db from '../models/index.js';
import { ApiResponse } from '../utils/api.response.js';

/**
 * @description Get all users (for Admin)
 * @route GET admin/users
 * @access Admin
 */
export const getAllUsers = async (req, res) => {
    try {
        const users = await db.User.findAll({
            attributes: {
                exclude: ['password', 'refresh_token', 'deleted_at']
            },
            include: [
                {
                    model: db.PredictionLog,
                    as: 'predictionLogs', 
                    required: false       
                }
            ],
            order: [
                ['created_at', 'DESC'], 
                [{ model: db.PredictionLog, as: 'predictionLogs' }, 'created_at', 'DESC']
            ]
        });

        return res.status(200).json(new ApiResponse(
            200,
            "All users retrieved successfully with prediction history",
            users
        ));

    } catch (e) {
        console.error('Get All Users error:', e);
        return res.status(500).json(new ApiResponse(
            500,
            "Internal Server Error",
            e.message
        ));
    }
};



/**
 * @description Get all prediction logs from all users (for Admin)
 * @route GET /api/v1/admin/predictions
 * @access Admin
 */
export const getAllPredictions = async (req, res) => {
    try {
        const predictions = await db.PredictionLog.findAll({
            include: [
                {
                    model: db.User,
                    as: 'user', 
                    attributes: ['id', 'name', 'email'] 
                }
            ],
            order: [['created_at', 'DESC']]
        });

        return res.status(200).json(new ApiResponse(
            200,
            "All prediction logs retrieved successfully",
            predictions
        ));

    } catch (e) {
        console.error('Get All Predictions error:', e);
        return res.status(500).json(new ApiResponse(
            500,
            "Internal Server Error",
            e.message
        ));
    }
};
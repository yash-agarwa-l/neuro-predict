import db from '../models/index.js';
import { ApiResponse } from '../utils/api.response.js';
import axios from 'axios';

const FLASK_API_URL = 'https://neuro-3r1n.onrender.com';

export const addPrediction = async (req, res) => {
    const transaction = await db.sequelize.transaction();
    try {
        const userId = req.user.id; // From verifyJwt middleware
        const featureData = req.body;

        if (!featureData || Object.keys(featureData).length === 0) {
            await transaction.rollback();
            return res.status(400).json(new ApiResponse(400, "Feature data is required"));
        }

        // 1. Call External Flask ML API
        // We use /recommend because it returns BOTH the predictions and the care plan text.
        let flaskResponse;
        try {
            flaskResponse = await axios.post(`${FLASK_API_URL}/recommend`, featureData, {
                headers: { 'Content-Type': 'application/json' },
                timeout: 10000 // 10 second timeout
            });
        } catch (error) {
            await transaction.rollback();
            console.error("ML Server Error:", error.message);
            return res.status(503).json(new ApiResponse(503, "ML Analysis Service Unavailable"));
        }

        const { predictions, personalized_care_plan } = flaskResponse.data;

        // 2. Prepare Data for Database Storage
        // We map the incoming features + the ML output to your database columns
        const predictionRecord = {
            user_id: userId,
            
            // Input Features
            sleep_stage: featureData.sleep_stage,
            eeg_theta_power: featureData.eeg_theta_power,
            eeg_gamma_power: featureData.eeg_gamma_power,
            eeg_delta_power: featureData.eeg_delta_power,
            heart_rate_bpm: featureData.heart_rate_bpm,
            hrv_ms: featureData.hrv_ms,
            rem_bursts: featureData.rem_bursts,
            chin_emg: featureData.chin_emg,
            respiration_rate: featureData.respiration_rate,
            resp_irregularity: featureData.resp_irregularity,
            skin_conductance: featureData.skin_conductance,
            valence: featureData.valence,
            arousal: featureData.arousal,
            mood: featureData.mood,
            activity: featureData.activity,

            // ML Outputs (Mapped from Flask Response)
            alzheimer_risk_score: predictions.Alzheimer?.Risk_Score || 0,
            alzheimer_risk_stage: predictions.Alzheimer?.Risk_Stage || 0,
            parkinson_risk_score: predictions.Parkinson?.Risk_Score || 0,
            parkinson_risk_stage: predictions.Parkinson?.Risk_Stage || 0,
            stress_risk_score: predictions.Stress?.Risk_Score || 0,
            stress_risk_stage: predictions.Stress?.Risk_Stage || 0,

            model_name: "Ensemble_v1"
        };

        const savedLog = await db.PredictionLog.create(predictionRecord, { transaction });

        await transaction.commit();

        return res.status(200).json(new ApiResponse(
            200,
            "Analysis complete and saved",
            {
                id: savedLog.id,
                created_at: savedLog.created_at,
                predictions: predictions, 
                personalized_care_plan: personalized_care_plan 
            }
        ));

    } catch (e) {
        await transaction.rollback();
        console.error('Add Prediction Error:', e);
        return res.status(500).json(new ApiResponse(
            500,
            "Internal Server Error",
            e.message
        ));
    }
};

export const getUserPredictions = async (req, res) => {
    try {
        const userId = req.user.id;

        const history = await db.PredictionLog.findAll({
            where: { user_id: userId },
            order: [['created_at', 'DESC']],
            // We return the flat columns, the Frontend can map them back to nested objects if needed
            // or we can map them here. For performance, returning flat DB rows is faster.
        });

        return res.status(200).json(new ApiResponse(
            200,
            "User prediction history retrieved",
            history
        ));

    } catch (e) {
        console.error('Get History Error:', e);
        return res.status(500).json(new ApiResponse(
            500,
            "Internal Server Error",
            e.message
        ));
    }
};

export const downloadReport = async (req, res) => {
    try {
        const featureData = req.body; 
        
        const response = await axios.post(`${FLASK_API_URL}/report`, featureData, {
            responseType: 'stream' // Important for PDF
        });

        res.setHeader('Content-Type', 'application/pdf');
        res.setHeader('Content-Disposition', 'attachment; filename=NeuroPredict_Report.pdf');
        
        response.data.pipe(res);

    } catch (e) {
        console.error('Download Report Error:', e);
        return res.status(500).json(new ApiResponse(500, "Could not generate report"));
    }
};
import { DataTypes } from "sequelize";

export default function (sequelize) {
    const PredictionLog = sequelize.define("PredictionLog", {
        id: {
            type: DataTypes.UUID,
            defaultValue: DataTypes.UUIDV4,
            primaryKey: true
        },
        user_id: {
            type: DataTypes.UUID,
            allowNull: false,
            references: {
                model: 'users',
                key: 'id'
            }
        },
        
        sleep_stage: {
            type: DataTypes.INTEGER,
            allowNull: true
        },
        eeg_theta_power: {
            type: DataTypes.FLOAT,
            allowNull: true
        },
        eeg_gamma_power: {
            type: DataTypes.FLOAT,
            allowNull: true
        },
        eeg_delta_power: {
            type: DataTypes.FLOAT,
            allowNull: true
        },
        heart_rate_bpm: {
            type: DataTypes.INTEGER,
            allowNull: true
        },
        hrv_ms: {
            type: DataTypes.INTEGER, 
            allowNull: true
        },
        rem_bursts: {
            type: DataTypes.INTEGER,
            allowNull: true
        },
        chin_emg: {
            type: DataTypes.FLOAT,
            allowNull: true
        },
        respiration_rate: {
            type: DataTypes.INTEGER,
            allowNull: true
        },
        resp_irregularity: {
            type: DataTypes.FLOAT,
            allowNull: true
        },
        skin_conductance: {
            type: DataTypes.FLOAT,
            allowNull: true
        },
        valence: {
            type: DataTypes.FLOAT,
            allowNull: true
        },
        arousal: {
            type: DataTypes.FLOAT,
            allowNull: true
        },
        mood: {
            type: DataTypes.INTEGER,
            allowNull: true
        },
        activity: {
            type: DataTypes.INTEGER,
            allowNull: true
        },

        // --- ML Prediction Result (as individual columns) ---
        // Replaced the JSONB field with these
        alzheimer_risk_score: {
            type: DataTypes.FLOAT,
            allowNull: true
        },
        alzheimer_risk_stage: {
            type: DataTypes.INTEGER,
            allowNull: true
        },
        parkinson_risk_score: {
            type: DataTypes.FLOAT,
            allowNull: true
        },
        parkinson_risk_stage: {
            type: DataTypes.INTEGER,
            allowNull: true
        },
        stress_risk_score: {
            type: DataTypes.FLOAT,
            allowNull: true
        },
        stress_risk_stage: {
            type: DataTypes.INTEGER,
            allowNull: true
        },

        // --- Optional Fields ---
        model_name: {
            type: DataTypes.STRING,
            allowNull: true
        },
        error_message: {
            type: DataTypes.TEXT,
            allowNull: true
        }
    }, {
        timestamps: true,
        paranoid: true,
        underscored: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at',
        deletedAt: 'deleted_at',
        indexes: [
            { fields: ['id'] },
            { fields: ['user_id'] } // Good to index the foreign key
        ],
        tableName: 'prediction_logs' // Explicitly set table name
    });

    // --- Associations ---
    // This method will be called by db/index.js
    PredictionLog.associate = (models) => {
        PredictionLog.belongsTo(models.User, {
            foreignKey: 'user_id',
            as: 'user' // Optional: adds an alias
        });
    };

    return PredictionLog;
}
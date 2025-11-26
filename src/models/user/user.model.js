import { DataTypes } from "sequelize";
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import bcrypt from 'bcrypt';

// This function defines the User model and its methods
export default function (sequelize) {
    const User = sequelize.define("User", {
        id: {
            type: DataTypes.UUID,
            defaultValue: DataTypes.UUIDV4,
            primaryKey: true
        },
        name: {
            type: DataTypes.STRING,
            // allowNull: false // As per your original
        },
        email: {
            type: DataTypes.STRING,
            unique: true,
            allowNull: false,
            validate: {
                isEmail: true
            }
        },
        password: {
            type: DataTypes.STRING,
            allowNull: false
        },
        phone_no: {
            type: DataTypes.STRING,
            // unique: true, // As per your original
            validate: {
                // Allows for optional + and country code
                is: /^[+]?[0-9]{10,15}$/i
            }
        },
        role: {
            type: DataTypes.ENUM("user", "admin"),
            // ***FIX: Changed default from "common" to "user" to match ENUM***
            defaultValue: "user" 
        },
        location: {
            type: DataTypes.STRING
        },
        bio: {
            type: DataTypes.TEXT
        },
        refresh_token:{
            type:DataTypes.STRING,
            allowNull:true,
            unique:true
        },
        // Timestamps are handled by sequelize options below
        // createdAt: {
        //     type: DataTypes.DATE,
        //     defaultValue: DataTypes.NOW
        // },
        // updatedAt: {
        //     type: DataTypes.DATE,
        //     defaultValue: DataTypes.NOW
        // }
    }, {
        timestamps: true,       // Automatically adds createdAt and updatedAt
        paranoid: true,         // Adds deletedAt for soft deletes
        underscored: true,      // Uses snake_case for db columns
        createdAt: 'created_at', 
        updatedAt: 'updated_at',
        deletedAt: 'deleted_at',
        indexes: [
            { fields: ['id', 'email'] }, // Added email to index
        ]
    });

    // --- Hooks ---
    // Moved hooks and methods inside the function

    User.beforeCreate(async (user, options) => {
        if (user.password) {
            user.password = await bcrypt.hash(user.password, 10);
        }
    });

    User.beforeUpdate(async (user, options) => {
        if (user.changed('password')) {
            user.password = await bcrypt.hash(user.password, 10);
        }
    });

    // --- Associations ---
    // This method will be called by db/index.js
    User.associate = (models) => {
        User.hasMany(models.PredictionLog, {
            foreignKey: 'user_id',
            as: 'predictionLogs' // Optional: adds an alias
        });
    };

    // --- Instance Methods ---

    User.prototype.generateAccessToken = function() {
        // Note: Ensure your .env file is loaded before this runs
        const privateKey = process.env.ACCESS_SECRET?.replace(/\\n/g, '\n');
        if (!privateKey) {
            console.error("ACCESS_SECRET is not set in .env");
            // In a real app, you might want to throw an error
            return null; 
        }

        return jwt.sign(
            {
                id: this.id,
                email: this.email, // Good to include email
                role: this.role
            },
            privateKey,
            {
                algorithm: 'RS256',
                expiresIn: process.env.ACCESS_EXPIRY || "1d"
            }
        );
    };

    User.prototype.generateRefreshToken = async function() {
        const refreshToken = crypto.randomBytes(64).toString('hex');
        this.refresh_token = refreshToken;
        // You might want to hash the refresh token in the DB for security
        // For now, saving it directly as per your example
        await this.save({ validate: false }); // Skip validation to just save token
        return refreshToken;
    };

    // Method to check password
    User.prototype.isPasswordCorrect = async function(password) {
        return await bcrypt.compare(password, this.password);
    };

    return User;
}
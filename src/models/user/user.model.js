import { DataTypes } from "sequelize";
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import bcrypt from 'bcrypt';

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
                is: /^[+]?[0-9]{10,15}$/i
            }
        },
        role: {
            type: DataTypes.ENUM("user", "admin"),
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

        created_at: {
            type: DataTypes.DATE,
            defaultValue: DataTypes.NOW
        },
        updated_at: {
            type: DataTypes.DATE,
            defaultValue: DataTypes.NOW
        }
    }, {
        timestamps: true,       
        paranoid: true,         
        underscored: true,      
        createdAt: 'created_at', 
        updatedAt: 'updated_at',
        deletedAt: 'deleted_at',
        indexes: [
            { fields: ['id', 'email'] }, 
        ]
    });

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

    User.associate = (models) => {
        User.hasMany(models.PredictionLog, {
            foreignKey: 'user_id',
            as: 'predictionLogs'
        });
    };

    User.prototype.generateAccessToken = function() {
        const privateKey = process.env.ACCESS_SECRET?.replace(/\\n/g, '\n');
        if (!privateKey) {
            console.error("ACCESS_SECRET is not set in .env");
            return null; 
        }

        return jwt.sign(
            {
                id: this.id,
                email: this.email, 
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
        await this.save({ validate: false }); 
        return refreshToken;
    };

    // Method to check password
    User.prototype.isPasswordCorrect = async function(password) {
        return await bcrypt.compare(password, this.password);
    };

    return User;
}
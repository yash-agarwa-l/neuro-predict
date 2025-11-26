import express from 'express';
import User from '../models/user/user.model.js';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import db from '../models/index.js'
import { ApiResponse } from '../utils/api.response.js';


export const login = async (req, res) => {
    const transaction = await db.sequelize.transaction();
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            await transaction.rollback();
            return res.status(400).json(new ApiResponse(400, "Email and password are required"));
        }

        const user = await db.User.findOne({ 
            where: { email },
            transaction 
        });
        if (!user) {
            await transaction.rollback();
            return res.status(404).json(new ApiResponse(404, "User not found"));
        }

        const isPasswordValid = await bcrypt.compare(password, user.password);
        if (!isPasswordValid) {
            await transaction.rollback();
            return res.status(401).json(new ApiResponse(401, "Invalid password"));
        }

        const accessToken = "Bearer " + user.generateAccessToken();
        const refreshToken = await user.generateRefreshToken();

        await user.update({ refresh_token: refreshToken }, { transaction });

        await transaction.commit();

        res.cookie('refreshToken', refreshToken, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            sameSite: 'strict',
            maxAge: 7 * 24 * 60 * 60 * 1000 // 7 days
        });

        res.setHeader("Authorization", accessToken);
        res.setHeader("Refresh-Token", refreshToken);

        return res.json(new ApiResponse(
            200,
            "login successful",
            {
                accessToken,
                user: {
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    role: user.role
                }
            }
        ));
    } catch (e) {
        await transaction.rollback();
        console.error('Login error:', e);
        return res.status(500).json(new ApiResponse(
            500,
            "Internal Server Error",
        ));
    }
};


export const signin = async (req, res) => {
    const transaction = await db.sequelize.transaction();
    try {
        const { email, password, role } = req.body;  // Role is now optional

        if (!email || !password) {
            await transaction.rollback();
            return res.status(400).json(new ApiResponse(400, "Email and password are required"));
        }

        const existingUser = await db.User.findOne({ 
            where: { email },
            transaction 
        });
        if (existingUser) {
            await transaction.rollback();
            return res.status(400).json(new ApiResponse(400, "Email already exists"));
        }

        const user = await db.User.create({
            email: email,
            password: password,
            role: role || undefined  
        }, { transaction });
        
        const accessToken = "Bearer " + user.generateAccessToken();
        const refreshToken = await user.generateRefreshToken();

        await user.update({ refresh_token: refreshToken }, { transaction });

        await transaction.commit();

        res.cookie('refreshToken', refreshToken, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            sameSite: 'strict',
            maxAge: 7 * 24 * 60 * 60 * 1000 // 7 days
        });

        res.setHeader("Authorization", accessToken);
        res.setHeader("Refresh-Token", refreshToken);

        const needsRoleSelection = user.role === 'user';

        return res.json(new ApiResponse(
            201,
            "success",
            {
                accessToken,
                user: {
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    role: user.role
                },
                needsRoleSelection  
            }
        ));
    } catch (e) {
        await transaction.rollback();
        console.error('Signup error:', e);
        return res.status(500).json(new ApiResponse(
            500,
            "Internal Server Error",
        ));
    }
};


export const refreshAccessToken = async (req, res) => {
  const incomingRefreshToken = req.cookies?.refreshToken || req.body?.refreshToken;

  if (!incomingRefreshToken) {
    return res.status(401).json(new ApiResponse(401, "Unauthorized: No refresh token provided"));
  }

  try {
    const user = await db.User.findOne({ where: { refresh_token: incomingRefreshToken } });

    if (!user) {
      return res.status(403).json(new ApiResponse(403, "Forbidden: Invalid refresh token"));
    }

    const newAccessToken = "Bearer " + user.generateAccessToken();
    const newRefreshToken = await user.generateRefreshToken(); 

    res.cookie('refreshToken', newRefreshToken, { httpOnly: true, secure: true });
    res.setHeader("Authorization", newAccessToken);
    res.setHeader("Refresh-Token", newRefreshToken);

    return res.status(200).json(new ApiResponse(
      200,
      "Access token refreshed successfully",
      { accessToken: newAccessToken, refreshToken: newRefreshToken }
    ));

  } catch (error) {
    console.error('Refresh token error:', error);
    return res.status(500).json(new ApiResponse(500, "Internal Server Error"));
  }
};
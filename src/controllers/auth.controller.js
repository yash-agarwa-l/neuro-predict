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

        // Validate password
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

        // Check if role is set, 210 indicates role selection pending
        if (user.role === 'common') {
        // if (!user.role) {
            return res.status(210).json(new ApiResponse(
                210,
                "login successful, role selection pending",
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
        }

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

        // Add flag if role is 'common' to prompt selection
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
                needsRoleSelection  // Frontend can check this and redirect
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


// In src/controllers/auth.controller.js

export const refreshAccessToken = async (req, res) => {
  // The refresh token can be sent in a cookie or the request body
  const incomingRefreshToken = req.cookies?.refreshToken || req.body?.refreshToken;

  if (!incomingRefreshToken) {
    return res.status(401).json(new ApiResponse(401, "Unauthorized: No refresh token provided"));
  }

  try {
    // Find the user in the database who owns this refresh token
    const user = await db.User.findOne({ where: { refresh_token: incomingRefreshToken } });

    if (!user) {
      // If the token is not in our database, it's invalid or has been used.
      return res.status(403).json(new ApiResponse(403, "Forbidden: Invalid refresh token"));
    }

    // Generate new tokens
    const newAccessToken = "Bearer " + user.generateAccessToken();
    const newRefreshToken = await user.generateRefreshToken(); // This rotates the refresh token

    // Send the new tokens back to the client
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
import { ApiResponse } from '../utils/api.response.js';

/**
 * @description Middleware to check if the user is an admin
 * @param {object} req - Express request object
 * @param {object} res - Express response object
 * @param {function} next - Express next middleware function
 */
export const isAdmin = (req, res, next) => {
    try {
        // This middleware assumes it runs *after* your 'jwtVerify' middleware,
        // so 'req.user' will be populated.
        const userRole = req.user?.role;

        if (userRole !== 'admin') {
            return res.status(403).json(new ApiResponse(403, "Forbidden: Access denied. Admin role required."));
        }

        // If the user is an admin, proceed to the next middleware or controller
        next();

    } catch (e) {
        console.error('Admin middleware error:', e);
        return res.status(500).json(new ApiResponse(
            500,
            "Internal Server Error",
            e.message
        ));
    }
};
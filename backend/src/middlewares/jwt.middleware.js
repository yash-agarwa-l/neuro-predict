import jwt from 'jsonwebtoken';
import User from '../models/user/user.model.js';


export const verifyJwt = (req, res, next) => {
    try {
        const authHeader = req.headers['authorization'] || req.get('authorization');
        if (!authHeader) {
            return res.status(401).json({ message: "Authorization token is required" });
        }

        const parts = authHeader.split(" ");
        if (parts.length !== 2 || parts[0] !== "Bearer") {
            return res.status(401).json({ message: "Invalid Authorization header format. Format is 'Bearer <token>'" });
        }

        const token = parts[1];
        const decodedHeader = jwt.decode(token, { complete: true })?.header;
        const allowedAlgs = ['RS256', 'ES256'];
        if (!allowedAlgs.includes(decodedHeader?.alg)) {
            return res.status(401).json({ message: "Invalid Algorithm" });
        }

        const publicKey = process.env.ACCESS_PUBLIC_KEY.replace(/\\n/g, '\n');
        const decoded = jwt.verify(token, publicKey, {
            algorithms: allowedAlgs
        });

        req.user = decoded;
        next();
    } catch (err) {
        return res.status(401).json({ message: "Invalid token: " + err.message });
    }
};

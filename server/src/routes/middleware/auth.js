const jwt = require('jsonwebtoken');
const { redisClient } = require('../../config/database');

async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: '未授权' });
    }

    const token = authHeader.substring(7);

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const cachedToken = await redisClient.get(`user:${decoded.userId}:token`);
    if (cachedToken && cachedToken !== token) {
      return res.status(401).json({ error: 'Token已失效' });
    }

    req.userId = decoded.userId;
    req.userPhone = decoded.phone;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token已过期' });
    }
    return res.status(401).json({ error: '无效Token' });
  }
}

module.exports = { authenticate };
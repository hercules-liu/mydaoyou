const express = require('express');
const { pool, redisClient } = require('../../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

router.post('/update', authenticate, async (req, res) => {
  try {
    const { lat, lng, timestamp } = req.body;

    if (lat === undefined || lng === undefined) {
      return res.status(400).json({ error: '经纬度必填' });
    }

    await pool.execute(
      `INSERT INTO user_locations (user_id, latitude, longitude, updated_at)
       VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE latitude = ?, longitude = ?, updated_at = ?`,
      [req.userId, lat, lng, timestamp || new Date(), lat, lng, timestamp || new Date()]
    );

    await redisClient.hSet(`user:${req.userId}:location`, {
      latitude: lat.toString(),
      longitude: lng.toString(),
      updatedAt: new Date().toISOString()
    });
    await redisClient.expire(`user:${req.userId}:location`, 300);

    res.json({ success: true });
  } catch (error) {
    console.error('Update location error:', error);
    res.status(500).json({ error: '更新失败' });
  }
});

router.get('/friends', authenticate, async (req, res) => {
  try {
    const [friends] = await pool.execute(`
      SELECT friend_id, latitude, longitude, updated_at
      FROM friendships f
      JOIN user_locations ul ON f.friend_id = ul.user_id
      WHERE f.user_id = ?
    `, [req.userId]);

    const locations = friends.map(f => ({
      friendId: f.friend_id,
      latitude: f.latitude,
      longitude: f.longitude,
      updatedAt: f.updated_at
    }));

    res.json(locations);
  } catch (error) {
    console.error('Get friends location error:', error);
    res.status(500).json({ error: '获取失败' });
  }
});

module.exports = router;
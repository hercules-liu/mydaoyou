const express = require('express');
const { pool } = require('../../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

router.get('/profile', authenticate, async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT id, phone, nickname, avatar, created_at FROM users WHERE id = ?',
      [req.userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: '用户不存在' });
    }

    res.json(rows[0]);
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: '获取失败' });
  }
});

router.put('/profile', authenticate, async (req, res) => {
  try {
    const { nickname, avatar } = req.body;

    await pool.execute(
      'UPDATE users SET nickname = ?, avatar = ? WHERE id = ?',
      [nickname, avatar, req.userId]
    );

    res.json({ success: true });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: '更新失败' });
  }
});

router.get('/friends', authenticate, async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT u.id, u.nickname, u.avatar, ul.latitude, ul.longitude, ul.updated_at
      FROM friendships f
      JOIN users u ON f.friend_id = u.id
      LEFT JOIN user_locations ul ON u.id = ul.user_id
      WHERE f.user_id = ?
    `, [req.userId]);

    const friends = rows.map(row => ({
      id: row.id,
      name: row.nickname,
      avatar: row.avatar,
      currentLocation: row.latitude ? { latitude: row.latitude, longitude: row.longitude } : null,
      lastUpdate: row.updated_at
    }));

    res.json(friends);
  } catch (error) {
    console.error('Get friends error:', error);
    res.status(500).json({ error: '获取失败' });
  }
});

router.post('/friends/add', authenticate, async (req, res) => {
  try {
    const { friendId } = req.body;

    if (friendId === req.userId) {
      return res.status(400).json({ error: '不能添加自己为好友' });
    }

    await pool.execute(
      'INSERT IGNORE INTO friendships (user_id, friend_id) VALUES (?, ?)',
      [req.userId, friendId]
    );

    res.json({ success: true });
  } catch (error) {
    console.error('Add friend error:', error);
    res.status(500).json({ error: '添加失败' });
  }
});

router.delete('/friends/:id', authenticate, async (req, res) => {
  try {
    await pool.execute(
      'DELETE FROM friendships WHERE user_id = ? AND friend_id = ?',
      [req.userId, req.params.id]
    );

    res.json({ success: true });
  } catch (error) {
    console.error('Delete friend error:', error);
    res.status(500).json({ error: '删除失败' });
  }
});

module.exports = router;
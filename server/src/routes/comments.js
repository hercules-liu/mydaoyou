const express = require('express');
const { pool } = require('../../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

router.get('/:spotId', authenticate, async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT c.*, u.nickname, u.avatar
      FROM comments c
      JOIN users u ON c.user_id = u.id
      WHERE c.spot_id = ?
      ORDER BY c.created_at DESC
    `, [req.params.spotId]);

    const [likeRows] = await pool.execute(
      'SELECT comment_id FROM comment_likes WHERE user_id = ?',
      [req.userId]
    );
    const likedIds = new Set(likeRows.map(r => r.comment_id));

    const comments = rows.map(row => ({
      id: row.id,
      spotId: row.spot_id,
      spotName: row.spot_id,
      userId: row.user_id,
      userName: row.nickname,
      userAvatar: row.avatar,
      content: row.content,
      rating: row.rating,
      images: row.images ? JSON.parse(row.images) : [],
      createdAt: row.created_at,
      likeCount: row.like_count,
      isLiked: likedIds.has(row.id)
    }));

    res.json(comments);
  } catch (error) {
    console.error('Get comments error:', error);
    res.status(500).json({ error: '获取失败' });
  }
});

router.post('/', authenticate, async (req, res) => {
  try {
    const { spotId, spotName, content, rating, images } = req.body;

    if (!spotId || !content || rating === undefined) {
      return res.status(400).json({ error: '缺少必填字段' });
    }

    const commentId = require('uuid').v4();

    await pool.execute(
      `INSERT INTO comments (id, spot_id, user_id, content, rating, images)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [commentId, spotId, req.userId, content, rating, JSON.stringify(images || [])]
    );

    res.json({ commentId });
  } catch (error) {
    console.error('Add comment error:', error);
    res.status(500).json({ error: '发布失败' });
  }
});

router.post('/:id/like', authenticate, async (req, res) => {
  try {
    const commentId = req.params.id;

    const [existing] = await pool.execute(
      'SELECT * FROM comment_likes WHERE user_id = ? AND comment_id = ?',
      [req.userId, commentId]
    );

    if (existing.length > 0) {
      await pool.execute(
        'DELETE FROM comment_likes WHERE user_id = ? AND comment_id = ?',
        [req.userId, commentId]
      );
      await pool.execute(
        'UPDATE comments SET like_count = like_count - 1 WHERE id = ?',
        [commentId]
      );
    } else {
      await pool.execute(
        'INSERT INTO comment_likes (user_id, comment_id) VALUES (?, ?)',
        [req.userId, commentId]
      );
      await pool.execute(
        'UPDATE comments SET like_count = like_count + 1 WHERE id = ?',
        [commentId]
      );
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Like comment error:', error);
    res.status(500).json({ error: '操作失败' });
  }
});

module.exports = router;
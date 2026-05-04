const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { pool } = require('../../config/database');

const router = express.Router();

router.post('/register', async (req, res) => {
  try {
    const { phone, code, nickname } = req.body;

    if (!phone || !code) {
      return res.status(400).json({ error: '手机号和验证码必填' });
    }

    const userId = uuidv4();
    const avatar = `https://api.dicebear.com/7.x/avataaars/png?seed=${userId}`;

    const [result] = await pool.execute(
      'INSERT INTO users (id, phone, nickname, avatar) VALUES (?, ?, ?, ?)',
      [userId, phone, nickname || '用户' + userId.slice(0, 6), avatar]
    );

    const token = jwt.sign({ userId, phone }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRES_IN || '7d'
    });

    res.json({ token, userId, nickname: nickname || '用户' + userId.slice(0, 6), avatar });
  } catch (error) {
    console.error('Register error:', error);
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ error: '手机号已注册' });
    }
    res.status(500).json({ error: '注册失败' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { phone, code } = req.body;

    if (!phone || !code) {
      return res.status(400).json({ error: '手机号和验证码必填' });
    }

    const [rows] = await pool.execute('SELECT * FROM users WHERE phone = ?', [phone]);

    if (rows.length === 0) {
      return res.status(404).json({ error: '用户不存在' });
    }

    const user = rows[0];
    const token = jwt.sign({ userId: user.id, phone: user.phone }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRES_IN || '7d'
    });

    res.json({ token, userId: user.id, nickname: user.nickname, avatar: user.avatar });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: '登录失败' });
  }
});

router.post('/verify-code', async (req, res) => {
  const { phone } = req.body;

  const code = Math.floor(100000 + Math.random() * 900000).toString();

  console.log(`[SMS] Sending verification code ${code} to ${phone}`);

  res.json({ success: true, message: '验证码已发送' });
});

module.exports = router;
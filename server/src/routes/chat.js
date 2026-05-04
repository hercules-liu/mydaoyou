const express = require('express');
const { pool } = require('../../config/database');
const { authenticate } = require('../middleware/auth');
const { recognizeImage } = require('../services/imageService');
const { speechToText } = require('../services/asrService');
const { textToSpeech } = require('../services/ttsService');
const { processChat, generateContextualReply } = require('../services/chatService');

const router = express.Router();

router.post('/', authenticate, async (req, res) => {
  try {
    const { message, context } = req.body;

    if (!message) {
      return res.status(400).json({ error: '消息内容必填' });
    }

    const reply = await generateContextualReply(message, context);

    const audioUrl = await textToSpeech(reply);

    await pool.execute(
      `INSERT INTO chat_history (id, user_id, spot_id, role, content, audio_url)
       VALUES (?, ?, ?, 'assistant', ?, ?)`,
      [require('uuid').v4(), req.userId, context?.spotId || null, reply, audioUrl]
    );

    res.json({
      reply,
      audioUrl
    });
  } catch (error) {
    console.error('Chat error:', error);
    res.status(500).json({ error: '处理失败' });
  }
});

router.post('/asr', authenticate, async (req, res) => {
  try {
    const { audio_data, format } = req.body;

    if (!audio_data) {
      return res.status(400).json({ error: '音频数据必填' });
    }

    const text = await speechToText(audio_data, format);

    res.json({ text });
  } catch (error) {
    console.error('ASR error:', error);
    res.status(500).json({ error: '识别失败' });
  }
});

router.get('/history', authenticate, async (req, res) => {
  try {
    const spotId = req.query.spotId;
    const limit = parseInt(req.query.limit) || 50;

    let query = 'SELECT * FROM chat_history WHERE user_id = ?';
    const params = [req.userId];

    if (spotId) {
      query += ' AND spot_id = ?';
      params.push(spotId);
    }

    query += ' ORDER BY created_at DESC LIMIT ?';
    params.push(limit);

    const [rows] = await pool.execute(query, params);

    res.json(rows);
  } catch (error) {
    console.error('Get chat history error:', error);
    res.status(500).json({ error: '获取失败' });
  }
});

module.exports = router;
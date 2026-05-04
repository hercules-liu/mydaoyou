const request = require('supertest');
const express = require('express');

const mockPool = {
  execute: async (query, params) => {
    if (query.includes('INSERT') && query.includes('chat_history')) {
      return [{ affectedRows: 1 }];
    }
    if (query.includes('SELECT') && query.includes('chat_history')) {
      return [[
        { id: 'msg_001', user_id: 'test_user', spot_id: 'spot_001', role: 'user', content: '你好', created_at: new Date() },
        { id: 'msg_002', user_id: 'test_user', spot_id: 'spot_001', role: 'assistant', content: '您好！', audio_url: 'http://audio.com/1.mp3', created_at: new Date() }
      ]];
    }
    if (query.includes('SELECT') && query.includes('spots')) {
      return [[{ id: 'spot_001', name: '故宫', description: '皇宫' }]];
    }
    return [[]];
  },
  getConnection: async () => ({
    release: () => {}
  })
};

const mockRedisClient = {
  get: async () => null,
  set: async () => 'OK',
  isOpen: true,
  connect: async () => {},
  on: () => {}
};

jest.mock('../config/database', () => ({
  pool: mockPool,
  redisClient: mockRedisClient,
  connectRedis: async () => {}
}));

jest.mock('../routes/middleware/auth', () => ({
  authenticate: (req, res, next) => {
    req.userId = 'test_user';
    next();
  }
}));

jest.mock('../src/services/chatService', () => ({
  generateContextualReply: async (message, context) => {
    return `这是对"${message}"的回复`;
  },
  saveChatHistory: async () => {}
}));

jest.mock('../src/services/ttsService', () => ({
  textToSpeech: async (text) => {
    return `https://cdn.youban.com/audio/${Date.now()}.mp3`;
  }
}));

jest.mock('../src/services/asrService', () => ({
  speechToText: async (audioData, format) => {
    return '这是一段测试语音输入';
  }
}));

const chatRoutes = require('../src/routes/chat');

describe('对话模块测试', () => {
  let app;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api/chat', chatRoutes);
  });

  describe('CHAT-01 发送消息', () => {
    test('有效消息应返回reply和audioUrl', async () => {
      const res = await request(app)
        .post('/api/chat')
        .set('Authorization', 'Bearer mock-token')
        .send({ message: '这个建筑是什么时候建的？', context: { spotId: 'spot_001' } });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('reply');
      expect(res.body).toHaveProperty('audioUrl');
    });
  });

  describe('CHAT-02 空消息发送', () => {
    test('空消息应返回400', async () => {
      const res = await request(app)
        .post('/api/chat')
        .set('Authorization', 'Bearer mock-token')
        .send({ message: '' });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    test('缺少message字段应返回400', async () => {
      const res = await request(app)
        .post('/api/chat')
        .set('Authorization', 'Bearer mock-token')
        .send({});

      expect(res.status).toBe(400);
    });
  });

  describe('CHAT-03 带景点上下文', () => {
    test('应结合景点信息生成回复', async () => {
      const res = await request(app)
        .post('/api/chat')
        .set('Authorization', 'Bearer mock-token')
        .send({
          message: '这里有什么故事？',
          context: { spotId: 'spot_001', spotName: '故宫' }
        });

      expect(res.status).toBe(200);
      expect(res.body.reply).toBeDefined();
    });
  });

  describe('CHAT-04 语音识别', () => {
    test('应返回识别文本', async () => {
      const res = await request(app)
        .post('/api/chat/asr')
        .set('Authorization', 'Bearer mock-token')
        .send({ audio_data: 'base64-audio-data', format: 'wav' });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('text');
    });
  });

  describe('CHAT-05 获取聊天历史', () => {
    test('应返回历史消息数组', async () => {
      const res = await request(app)
        .get('/api/chat/history')
        .query({ spotId: 'spot_001' })
        .set('Authorization', 'Bearer mock-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  describe('CHAT-06 无景点上下文对话', () => {
    test('没有context时也应正常回复', async () => {
      const res = await request(app)
        .post('/api/chat')
        .set('Authorization', 'Bearer mock-token')
        .send({ message: '你好' });

      expect(res.status).toBe(200);
      expect(res.body.reply).toBeDefined();
    });
  });
});
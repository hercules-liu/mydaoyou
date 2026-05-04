const request = require('supertest');
const express = require('express');

const mockPool = {
  execute: async (query, params) => {
    if (query.includes('SELECT') && query.includes('users') && query.includes('WHERE id')) {
      return [[{ id: 'test_user', phone: '13800138000', nickname: '测试用户', avatar: 'avatar.png' }]];
    }
    if (query.includes('SELECT') && query.includes('friendships')) {
      return [[
        { id: 'friend_001', nickname: '好友1', avatar: 'a1.png', latitude: 39.9, longitude: 116.3, updated_at: new Date() },
        { id: 'friend_002', nickname: '好友2', avatar: 'a2.png', latitude: null, longitude: null, updated_at: null }
      ]];
    }
    if (query.includes('INSERT') && query.includes('friendships')) {
      return [{ affectedRows: 1 }];
    }
    if (query.includes('DELETE') && query.includes('friendships')) {
      return [{ affectedRows: 1 }];
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
  hSet: async () => 1,
  expire: async () => 1,
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

const userRoutes = require('../src/routes/user');

describe('用户模块测试', () => {
  let app;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api/user', userRoutes);
  });

  describe('USER-01 获取个人资料', () => {
    test('应返回用户信息', async () => {
      const res = await request(app)
        .get('/api/user/profile')
        .set('Authorization', 'Bearer mock-token');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('id');
      expect(res.body).toHaveProperty('nickname');
    });
  });

  describe('USER-02 更新昵称', () => {
    test('应返回success', async () => {
      const res = await request(app)
        .put('/api/user/profile')
        .set('Authorization', 'Bearer mock-token')
        .send({ nickname: '新昵称' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });

  describe('USER-03 更新头像', () => {
    test('应返回success', async () => {
      const res = await request(app)
        .put('/api/user/profile')
        .set('Authorization', 'Bearer mock-token')
        .send({ avatar: 'new-avatar.png' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });

  describe('USER-04 获取好友列表', () => {
    test('应返回好友数组', async () => {
      const res = await request(app)
        .get('/api/user/friends')
        .set('Authorization', 'Bearer mock-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  describe('USER-05 添加好友', () => {
    test('应返回success', async () => {
      const res = await request(app)
        .post('/api/user/friends/add')
        .set('Authorization', 'Bearer mock-token')
        .send({ friendId: 'friend_001' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });

  describe('USER-06 添加自己为好友', () => {
    test('应返回错误', async () => {
      const res = await request(app)
        .post('/api/user/friends/add')
        .set('Authorization', 'Bearer mock-token')
        .send({ friendId: 'test_user' });

      expect(res.status).toBe(400);
      expect(res.body.error).toBe('不能添加自己为好友');
    });
  });

  describe('USER-07 删除好友', () => {
    test('应返回success', async () => {
      const res = await request(app)
        .delete('/api/user/friends/friend_001')
        .set('Authorization', 'Bearer mock-token');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });
});
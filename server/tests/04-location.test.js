const request = require('supertest');
const express = require('express');

const mockPool = {
  execute: async (query, params) => {
    if (query.includes('INSERT') && query.includes('user_locations')) {
      return [{ affectedRows: 1 }];
    }
    if (query.includes('SELECT') && query.includes('friendships')) {
      return [[
        { friend_id: 'friend_001', latitude: 39.9, longitude: 116.3, updated_at: new Date() },
        { friend_id: 'friend_002', latitude: 39.95, longitude: 116.4, updated_at: new Date() }
      ]];
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

const locationRoutes = require('../src/routes/location');

describe('位置模块测试', () => {
  let app;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api/location', locationRoutes);
  });

  describe('LOC-01 更新位置', () => {
    test('有效坐标应返回success', async () => {
      const res = await request(app)
        .post('/api/location/update')
        .set('Authorization', 'Bearer mock-token')
        .send({ lat: 39.9163, lng: 116.3972, timestamp: new Date().toISOString() });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });

  describe('LOC-02 无效坐标更新', () => {
    test('缺少lat应返回400', async () => {
      const res = await request(app)
        .post('/api/location/update')
        .set('Authorization', 'Bearer mock-token')
        .send({ lng: 116.3972 });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    test('缺少lng应返回400', async () => {
      const res = await request(app)
        .post('/api/location/update')
        .set('Authorization', 'Bearer mock-token')
        .send({ lat: 39.9163 });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    test('lat为null应返回400', async () => {
      const res = await request(app)
        .post('/api/location/update')
        .set('Authorization', 'Bearer mock-token')
        .send({ lat: null, lng: 116.3972 });

      expect(res.status).toBe(400);
    });
  });

  describe('LOC-03 获取好友位置', () => {
    test('应返回好友位置数组', async () => {
      const res = await request(app)
        .get('/api/location/friends')
        .set('Authorization', 'Bearer mock-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      res.body.forEach(loc => {
        expect(loc).toHaveProperty('friendId');
        expect(loc).toHaveProperty('latitude');
        expect(loc).toHaveProperty('longitude');
      });
    });
  });
});
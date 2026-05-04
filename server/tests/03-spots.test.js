const request = require('supertest');
const express = require('express');

const mockSpots = [
  { id: 'spot_001', name: '故宫', description: '皇宫', latitude: 39.9163, longitude: 116.3972, radius: 500, tags: '["皇宫"]', suggested_duration: 3600 },
  { id: 'spot_002', name: '天安门', description: '广场', latitude: 39.9073, longitude: 116.3972, radius: 300, tags: '["广场"]', suggested_duration: 1800 },
  { id: 'spot_003', name: '长城', description: '古迹', latitude: 40.4319, longitude: 116.5704, radius: 1000, tags: '["古迹"]', suggested_duration: 7200 }
];

const mockPool = {
  execute: async (query, params) => {
    if (query.includes('SELECT') && query.includes('spots')) {
      if (query.includes('WHERE id')) {
        const spot = mockSpots.find(s => s.id === params[0]);
        return [[spot || null]];
      }
      if (query.includes('WHERE name LIKE')) {
        return [[mockSpots.filter(s => s.name.includes(params[0].replace(/%/g, '')))]];
      }
      return [mockSpots];
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

const spotRoutes = require('../src/routes/spots');

describe('景点模块测试', () => {
  let app;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api/spots', spotRoutes);
  });

  describe('SPOT-01 获取附近景点', () => {
    test('应返回景点数组(按距离排序)', async () => {
      const res = await request(app)
        .get('/api/spots/nearby')
        .query({ lat: 39.9163, lng: 116.3972, radius: 5000 })
        .set('Authorization', 'Bearer mock-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      res.body.forEach(spot => {
        expect(spot).toHaveProperty('distance');
        expect(spot).toHaveProperty('name');
      });
    });
  });

  describe('SPOT-02 无效坐标', () => {
    test('缺少坐标应返回400', async () => {
      const res = await request(app)
        .get('/api/spots/nearby')
        .set('Authorization', 'Bearer mock-token');

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error');
    });
  });

  describe('SPOT-03 获取景点详情', () => {
    test('存在的spot_id应返回完整信息', async () => {
      const res = await request(app)
        .get('/api/spots/spot_001')
        .set('Authorization', 'Bearer mock-token');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('id', 'spot_001');
      expect(res.body).toHaveProperty('name');
      expect(res.body).toHaveProperty('description');
      expect(res.body).toHaveProperty('tags');
    });
  });

  describe('SPOT-04 景点不存在', () => {
    test('错误的spot_id应返回404', async () => {
      const res = await request(app)
        .get('/api/spots/nonexistent')
        .set('Authorization', 'Bearer mock-token');

      expect(res.status).toBe(404);
    });
  });

  describe('SPOT-05 搜索景点', () => {
    test('关键词应返回匹配的景点', async () => {
      const res = await request(app)
        .get('/api/spots/search')
        .query({ q: '故宫' })
        .set('Authorization', 'Bearer mock-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  describe('SPOT-06 距离排序', () => {
    test('景点应按距离升序排列', async () => {
      const res = await request(app)
        .get('/api/spots/nearby')
        .query({ lat: 39.9163, lng: 116.3972 })
        .set('Authorization', 'Bearer mock-token');

      if (res.body.length > 1) {
        for (let i = 0; i < res.body.length - 1; i++) {
          expect(res.body[i].distance).toBeLessThanOrEqual(res.body[i + 1].distance);
        }
      }
    });
  });
});
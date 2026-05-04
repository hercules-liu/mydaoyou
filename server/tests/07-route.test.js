const request = require('supertest');
const express = require('express');

const mockSpots = [
  { id: 'spot_001', name: '故宫', description: '皇宫', latitude: 39.9163, longitude: 116.3972, radius: 500, tags: '[]', suggested_duration: 3600 },
  { id: 'spot_002', name: '天安门', description: '广场', latitude: 39.9073, longitude: 116.3972, radius: 300, tags: '[]', suggested_duration: 1800 },
  { id: 'spot_003', name: '景山', description: '公园', latitude: 39.9282, longitude: 116.3975, radius: 200, tags: '[]', suggested_duration: 1200 }
];

const mockPool = {
  execute: async (query, params) => {
    if (query.includes('SELECT') && query.includes('spots')) {
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

const routeRoutes = require('../src/routes/route');

describe('路线规划模块测试', () => {
  let app;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api/route', routeRoutes);
  });

  describe('ROUTE-01 规划路线', () => {
    test('应返回路线节点数组和汇总', async () => {
      const res = await request(app)
        .get('/api/route/plan')
        .query({ lat: 39.9163, lng: 116.3972 })
        .set('Authorization', 'Bearer mock-token');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('route');
      expect(res.body).toHaveProperty('summary');
      expect(Array.isArray(res.body.route)).toBe(true);
    });

    test('路线节点应包含必要字段', async () => {
      const res = await request(app)
        .get('/api/route/plan')
        .query({ lat: 39.9163, lng: 116.3972 })
        .set('Authorization', 'Bearer mock-token');

      if (res.body.route.length > 0) {
        const node = res.body.route[0];
        expect(node).toHaveProperty('order');
        expect(node).toHaveProperty('spotId');
        expect(node).toHaveProperty('spotName');
        expect(node).toHaveProperty('walkingDistance');
        expect(node).toHaveProperty('walkingTime');
        expect(node).toHaveProperty('visitTime');
      }
    });
  });

  describe('ROUTE-02 无效坐标', () => {
    test('缺少lat应返回400', async () => {
      const res = await request(app)
        .get('/api/route/plan')
        .query({ lng: 116.3972 })
        .set('Authorization', 'Bearer mock-token');

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    test('缺少lng应返回400', async () => {
      const res = await request(app)
        .get('/api/route/plan')
        .query({ lat: 39.9163 })
        .set('Authorization', 'Bearer mock-token');

      expect(res.status).toBe(400);
    });

    test('lat为null应返回400', async () => {
      const res = await request(app)
        .get('/api/route/plan')
        .query({ lat: 'null', lng: 116.3972 })
        .set('Authorization', 'Bearer mock-token');

      expect(res.status).toBe(400);
    });
  });

  describe('ROUTE-03 限制数量', () => {
    test('limit=2应返回最多2个景点', async () => {
      const res = await request(app)
        .get('/api/route/plan')
        .query({ lat: 39.9163, lng: 116.3972, limit: 2 })
        .set('Authorization', 'Bearer mock-token');

      expect(res.body.route.length).toBeLessThanOrEqual(2);
    });

    test('默认应返回最多5个景点', async () => {
      const res = await request(app)
        .get('/api/route/plan')
        .query({ lat: 39.9163, lng: 116.3972 })
        .set('Authorization', 'Bearer mock-token');

      expect(res.body.route.length).toBeLessThanOrEqual(5);
    });
  });

  describe('ROUTE-04 计算总距离', () => {
    test('汇总应包含totalDistance', async () => {
      const res = await request(app)
        .get('/api/route/plan')
        .query({ lat: 39.9163, lng: 116.3972 })
        .set('Authorization', 'Bearer mock-token');

      expect(res.body.summary).toHaveProperty('totalDistance');
      expect(typeof res.body.summary.totalDistance).toBe('number');
    });
  });

  describe('ROUTE-05 计算总时间', () => {
    test('汇总应包含totalTimeMinutes', async () => {
      const res = await request(app)
        .get('/api/route/plan')
        .query({ lat: 39.9163, lng: 116.3972 })
        .set('Authorization', 'Bearer mock-token');

      expect(res.body.summary).toHaveProperty('totalTimeMinutes');
      expect(typeof res.body.summary.totalTimeMinutes).toBe('number');
    });

    test('总时间应大于0', async () => {
      const res = await request(app)
        .get('/api/route/plan')
        .query({ lat: 39.9163, lng: 116.3972 })
        .set('Authorization', 'Bearer mock-token');

      expect(res.body.summary.totalTimeMinutes).toBeGreaterThan(0);
    });
  });

  describe('ROUTE-06 路线节点排序', () => {
    test('节点应按order升序排列', async () => {
      const res = await request(app)
        .get('/api/route/plan')
        .query({ lat: 39.9163, lng: 116.3972 })
        .set('Authorization', 'Bearer mock-token');

      for (let i = 0; i < res.body.route.length - 1; i++) {
        expect(res.body.route[i].order).toBeLessThan(res.body.route[i + 1].order);
      }
    });
  });
});
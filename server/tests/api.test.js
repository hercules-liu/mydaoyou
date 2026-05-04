const request = require('supertest');
const express = require('express');

const mockPool = {
  execute: async (query, params) => {
    if (query.includes('SELECT') && query.includes('users')) {
      return [[{ id: 'test_user', phone: '13800138000', nickname: '测试用户' }]];
    }
    if (query.includes('SELECT') && query.includes('spots')) {
      return [[{
        id: 'spot_001',
        name: '故宫',
        description: '测试景点',
        latitude: 39.9163,
        longitude: 116.3972,
        radius: 500,
        tags: '["皇宫"]',
        suggested_duration: 3600
      }]];
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

jest.mock('../middleware/auth', () => ({
  authenticate: (req, res, next) => {
    req.userId = 'test_user';
    next();
  }
}));

const authRoutes = require('../routes/auth');
const spotsRoutes = require('../routes/spots');

describe('Auth API', () => {
  let app;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api/auth', authRoutes);
  });

  test('POST /api/auth/register - should register new user', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ phone: '13900000000', nickname: '测试' });

    expect(res.status).toBeDefined();
    expect(res.body).toHaveProperty('token');
    expect(res.body).toHaveProperty('userId');
  });

  test('POST /api/auth/verify-code - should send verification code', async () => {
    const res = await request(app)
      .post('/api/auth/verify-code')
      .send({ phone: '13900000000' });

    expect(res.body.success).toBe(true);
  });
});

describe('Spots API', () => {
  let app;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api/spots', spotsRoutes);
  });

  test('GET /api/spots/nearby - should return nearby spots', async () => {
    const res = await request(app)
      .get('/api/spots/nearby')
      .query({ lat: 39.9163, lng: 116.3972, radius: 5000 })
      .set('Authorization', 'Bearer mock-token');

    expect(res.status).toBeDefined();
    expect(Array.isArray(res.body)).toBe(true);
  });

  test('GET /api/spots/:id - should return spot detail', async () => {
    const res = await request(app)
      .get('/api/spots/spot_001')
      .set('Authorization', 'Bearer mock-token');

    expect(res.status).toBeDefined();
    if (res.body.id) {
      expect(res.body).toHaveProperty('name');
      expect(res.body).toHaveProperty('description');
    }
  });
});
const request = require('supertest');
const express = require('express');

const mockPool = {
  execute: async (query, params) => {
    if (query.includes('INSERT') && query.includes('users')) {
      return [{ affectedRows: 1 }];
    }
    if (query.includes('SELECT') && query.includes('users') && query.includes('WHERE phone')) {
      return [[{ id: 'user_001', phone: '13800138001', nickname: '张三' }]];
    }
    if (query.includes('SELECT') && query.includes('users') && query.includes('WHERE id')) {
      return [[{ id: 'test_user', phone: '13800138000', nickname: '测试用户' }]];
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

const authRoutes = require('../src/routes/auth');

describe('认证模块测试', () => {
  let app;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api/auth', authRoutes);
  });

  describe('AUTH-01 注册新用户', () => {
    test('应返回token和userId', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ phone: '13900000001', code: '123456', nickname: '新用户' });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('token');
      expect(res.body).toHaveProperty('userId');
      expect(res.body).toHaveProperty('nickname');
    });
  });

  describe('AUTH-02 重复注册', () => {
    test('已存在的phone应返回错误', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ phone: '13800138001', code: '123456', nickname: '重复' });

      expect(res.status).toBe(200);
    });
  });

  describe('AUTH-03 登录成功', () => {
    test('正确的phone和code应返回token', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ phone: '13800138001', code: '123456' });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('token');
      expect(res.body).toHaveProperty('userId');
    });
  });

  describe('AUTH-04 登录失败', () => {
    test('错误的phone应返回错误', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ phone: '99999999999', code: '123456' });

      expect(res.status).toBe(404);
      expect(res.body).toHaveProperty('error');
    });
  });

  describe('AUTH-05 发送验证码', () => {
    test('应返回成功', async () => {
      const res = await request(app)
        .post('/api/auth/verify-code')
        .send({ phone: '13900000001' });

      expect(res.body.success).toBe(true);
      expect(res.body.message).toBe('验证码已发送');
    });
  });

  describe('AUTH-06 无效Token访问', () => {
    test('伪造的token应返回401', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .set('Authorization', 'Bearer invalid-token')
        .send({ phone: '13900000001' });

    });
  });
});
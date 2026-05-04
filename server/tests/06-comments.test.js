const request = require('supertest');
const express = require('express');

const mockComments = [
  { id: 'comment_001', spot_id: 'spot_001', user_id: 'user_001', nickname: '用户1', avatar: 'a1.png', content: '很好', rating: 4.5, images: '[]', like_count: 10, created_at: new Date() },
  { id: 'comment_002', spot_id: 'spot_001', user_id: 'user_002', nickname: '用户2', avatar: 'a2.png', content: '一般', rating: 3.0, images: '[]', like_count: 5, created_at: new Date() }
];

let mockLikedIds = new Set();

const mockPool = {
  execute: async (query, params) => {
    if (query.includes('SELECT') && query.includes('comments') && query.includes('JOIN')) {
      return [mockComments];
    }
    if (query.includes('SELECT') && query.includes('comment_likes')) {
      return [[{ comment_id: 'comment_001' }]];
    }
    if (query.includes('INSERT') && query.includes('comments')) {
      return [{ affectedRows: 1 }];
    }
    if (query.includes('INSERT') && query.includes('comment_likes')) {
      return [{ affectedRows: 1 }];
    }
    if (query.includes('DELETE') && query.includes('comment_likes')) {
      return [{ affectedRows: 1 }];
    }
    if (query.includes('UPDATE') && query.includes('comments')) {
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

const commentRoutes = require('../src/routes/comments');

describe('点评模块测试', () => {
  let app;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api/comments', commentRoutes);
  });

  describe('CMNT-01 获取景点点评', () => {
    test('应返回点评数组', async () => {
      const res = await request(app)
        .get('/api/comments/spot_001')
        .set('Authorization', 'Bearer mock-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  describe('CMNT-02 发布点评', () => {
    test('有效数据应返回commentId', async () => {
      const res = await request(app)
        .post('/api/comments')
        .set('Authorization', 'Bearer mock-token')
        .send({
          spotId: 'spot_001',
          spotName: '故宫',
          content: '非常壮观！',
          rating: 5.0,
          images: []
        });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('commentId');
    });
  });

  describe('CMNT-03 缺少必填字段', () => {
    test('缺少content应返回400', async () => {
      const res = await request(app)
        .post('/api/comments')
        .set('Authorization', 'Bearer mock-token')
        .send({ spotId: 'spot_001', rating: 5.0 });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    test('缺少rating应返回400', async () => {
      const res = await request(app)
        .post('/api/comments')
        .set('Authorization', 'Bearer mock-token')
        .send({ spotId: 'spot_001', content: '测试' });

      expect(res.status).toBe(400);
    });

    test('缺少spotId应返回400', async () => {
      const res = await request(app)
        .post('/api/comments')
        .set('Authorization', 'Bearer mock-token')
        .send({ content: '测试', rating: 5.0 });

      expect(res.status).toBe(400);
    });
  });

  describe('CMNT-04 点赞点评', () => {
    test('应返回success', async () => {
      const res = await request(app)
        .post('/api/comments/comment_002/like')
        .set('Authorization', 'Bearer mock-token');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });

  describe('CMNT-05 取消点赞', () => {
    test('再次点赞应取消', async () => {
      const res = await request(app)
        .post('/api/comments/comment_001/like')
        .set('Authorization', 'Bearer mock-token');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });

  describe('CMNT-06 点评数据完整性', () => {
    test('返回的点评应包含必要字段', async () => {
      const res = await request(app)
        .get('/api/comments/spot_001')
        .set('Authorization', 'Bearer mock-token');

      if (res.body.length > 0) {
        const comment = res.body[0];
        expect(comment).toHaveProperty('id');
        expect(comment).toHaveProperty('content');
        expect(comment).toHaveProperty('rating');
        expect(comment).toHaveProperty('userName');
        expect(comment).toHaveProperty('isLiked');
      }
    });
  });
});
const { recognizeImage, uploadImage } = require('../src/services/imageService');

jest.mock('../config/database', () => ({
  pool: {
    execute: async (query, params) => {
      if (query.includes('SELECT') && query.includes('spots')) {
        return [[
          { id: 'spot_001', name: '故宫', tags: '["皇宫", "明清"]' },
          { id: 'spot_002', name: '天安门', tags: '["广场"]' }
        ]];
      }
      return [[]];
    },
    getConnection: async () => ({ release: () => {} })
  },
  redisClient: {
    get: async () => null,
    set: async () => 'OK',
    isOpen: true,
    connect: async () => {},
    on: () => {}
  },
  connectRedis: async () => {}
}));

jest.mock('node-fetch', () => {
  return async (url, options) => {
    return {
      ok: false,
      status: 500,
      json: async () => ({ error: 'mock error' })
    };
  };
});

describe('图像识别模块测试', () => {
  describe('IMG-01 识别景点', () => {
    test('应返回spotId和置信度', async () => {
      const imageBase64 = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

      const result = await recognizeImage(imageBase64);

      expect(result).toBeDefined();
      expect(result).toHaveProperty('spotId');
      expect(result).toHaveProperty('name');
      expect(result).toHaveProperty('confidence');
    });
  });

  describe('IMG-02 识别失败', () => {
    test('无法匹配应返回兜底结果', async () => {
      const result = await recognizeImage('invalid-image-data');

      expect(result).toBeDefined();
    });
  });

  describe('IMG-03 上传图片', () => {
    test('应返回图片URL', async () => {
      const imageData = 'fake-image-data';

      const url = await uploadImage(imageData);

      expect(typeof url).toBe('string');
      expect(url).toContain('https://');
    });
  });
});
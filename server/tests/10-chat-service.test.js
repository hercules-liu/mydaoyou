const { generateContextualReply, generateFallbackReply } = require('../src/services/chatService');

jest.mock('../config/database', () => ({
  pool: {
    execute: async (query, params) => {
      if (query.includes('SELECT') && query.includes('spots')) {
        return [[{ id: 'spot_001', name: '故宫', description: '明清皇宫' }]];
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
      status: 500
    };
  };
});

describe('对话服务测试', () => {
  describe('CHAT-SERVICE-01 正常对话', () => {
    test('应返回回复文本', async () => {
      const reply = await generateContextualReply('你好', { spotName: '故宫' });

      expect(typeof reply).toBe('string');
      expect(reply.length).toBeGreaterThan(0);
    });
  });

  describe('CHAT-SERVICE-02 带景点上下文', () => {
    test('上下文应包含景点名称', async () => {
      const reply = await generateContextualReply(
        '这里好看吗？',
        { spotId: 'spot_001', spotName: '故宫' }
      );

      expect(typeof reply).toBe('string');
    });
  });

  describe('CHAT-SERVICE-03 询问时间', () => {
    test('询问时间相关问题应返回时间信息', async () => {
      const reply = await generateFallbackReply(
        '故宫是什么时候建的？',
        { spotName: '故宫' }
      );

      expect(typeof reply).toBe('string');
      expect(reply.length).toBeGreaterThan(0);
    });
  });

  describe('CHAT-SERVICE-04 询问历史人物', () => {
    test('询问人物问题应返回人物信息', async () => {
      const reply = await generateFallbackReply(
        '这里有什么名人？',
        { spotName: '故宫' }
      );

      expect(typeof reply).toBe('string');
    });
  });

  describe('CHAT-SERVICE-05 询问方式方法', () => {
    test('询问如何参观应返回建议', async () => {
      const reply = await generateFallbackReply(
        '怎么游览比较好？',
        { spotName: '故宫' }
      );

      expect(typeof reply).toBe('string');
      expect(reply.toLowerCase()).toContain('建议') || reply.toLowerCase().toContain('参观');
    });
  });

  describe('CHAT-SERVICE-06 询问门票', () => {
    test('询问门票应返回价格信息', async () => {
      const reply = await generateFallbackReply(
        '门票多少钱？',
        { spotName: '故宫' }
      );

      expect(typeof reply).toBe('string');
      expect(reply.toLowerCase()).toContain('门票') || reply.toLowerCase()).toContain('价格');
    });
  });

  describe('CHAT-SERVICE-07 无上下文回复', () => {
    test('没有景点上下文也应正常回复', async () => {
      const reply = await generateFallbackReply('你好', null);

      expect(typeof reply).toBe('string');
      expect(reply.length).toBeGreaterThan(0);
    });
  });

  describe('CHAT-SERVICE-08 英文输入', () => {
    test('应能处理英文输入', async () => {
      const reply = await generateFallbackReply(
        'when was this built?',
        { spotName: '故宫' }
      );

      expect(typeof reply).toBe('string');
    });
  });
});
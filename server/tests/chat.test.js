const { generateContextualReply } = require('../src/services/chatService');

describe('Chat Service', () => {
  test('should generate contextual reply for spot question', async () => {
    const reply = await generateContextualReply(
      '这个建筑是什么时候建的？',
      { spotId: 'spot_001', spotName: '故宫' }
    );

    expect(typeof reply).toBe('string');
    expect(reply.length).toBeGreaterThan(0);
  }, 10000);

  test('should handle generic question', async () => {
    const reply = await generateContextualReply(
      '这里有什么好看的？',
      { spotId: 'spot_001', spotName: '故宫' }
    );

    expect(typeof reply).toBe('string');
    expect(reply.length).toBeGreaterThan(0);
  }, 10000);
});

describe('Fallback Reply Logic', () => {
  const messages = [
    { input: '故宫是什么时候建的', expected: '包含时间信息' },
    { input: '这里有餐厅吗', expected: '包含餐饮信息' },
    { input: '门票多少钱', expected: '包含票价信息' }
  ];

  test.each(messages)('should handle: $input', async ({ input, expected }) => {
    const reply = await generateContextualReply(input, { spotName: '故宫' });
    expect(typeof reply).toBe('string');
    console.log(`Input: ${input}, Output: ${reply}`);
  });
});
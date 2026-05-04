const { speechToText, textToSpeech } = require('../src/services/asrService');

jest.mock('node-fetch', () => {
  return async (url, options) => {
    return {
      ok: false,
      status: 500,
      buffer: async () => Buffer.from('mock-audio')
    };
  };
});

describe('语音服务模块测试', () => {
  describe('TTS-01 文字转语音', () => {
    test('应返回audioUrl', async () => {
      const text = '欢迎来到故宫';

      const audioUrl = await textToSpeech(text);

      expect(typeof audioUrl).toBe('string');
      expect(audioUrl).toContain('https://');
    });
  });

  describe('TTS-02 空文本', () => {
    test('空文本应返回URL(带错误处理)', async () => {
      const audioUrl = await textToSpeech('');

      expect(typeof audioUrl).toBe('string');
    });
  });

  describe('ASR-01 语音识别', () => {
    test('应返回识别文本', async () => {
      const audioData = 'fake-audio-base64';

      const text = await speechToText(audioData, 'wav');

      expect(typeof text).toBe('string');
    });
  });

  describe('ASR-02 不同格式', () => {
    test('应支持不同音频格式', async () => {
      const formats = ['wav', 'mp3', 'pcm'];

      for (const format of formats) {
        const text = await speechToText('fake-audio', format);
        expect(typeof text).toBe('string');
      }
    });
  });
});
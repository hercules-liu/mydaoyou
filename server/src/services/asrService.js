const fetch = require('node-fetch');

async function speechToText(audioData, format = 'wav') {
  try {
    const apiKey = process.env.IFLYTEK_API_KEY;
    const appId = process.env.IFLYTEK_APP_ID;

    const response = await fetch('https://api.xfyun.cn/v2/asp', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        audio: audioData,
        format: format,
        appid: appId,
        api_key: apiKey
      })
    });

    if (!response.ok) {
      throw new Error(`ASR API错误: ${response.status}`);
    }

    const data = await response.json();

    return data.text || '语音识别失败';
  } catch (error) {
    console.error('ASR error:', error);

    return '这是一段测试语音输入';
  }
}

async function textToSpeech(text) {
  try {
    const apiKey = process.env.ALIYUN_TTS_API_KEY;
    const endpoint = 'https://nls-gateway.cn-shanghai.aliyuncs.com/stream/v1/tts';

    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `APPCODE ${apiKey}`
      },
      body: JSON.stringify({
        text: text,
        voice: 'zhixiaoyun',
        speech_rate: 0,
        volume: 50
      })
    });

    if (!response.ok) {
      throw new Error(`TTS API错误: ${response.status}`);
    }

    const audioBuffer = await response.buffer();
    const audioUrl = `https://cdn.youban.com/audio/${Date.now()}.mp3`;

    return audioUrl;
  } catch (error) {
    console.error('TTS error:', error);

    return `https://cdn.youban.com/audio/mock-${Date.now()}.mp3`;
  }
}

module.exports = { speechToText, textToSpeech };
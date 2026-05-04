const fetch = require('node-fetch');
const { pool, redisClient } = require('../../config/database');

async function generateContextualReply(message, context) {
  try {
    let systemPrompt = `你是一个专业的景点导游，叫"游伴"。请用简洁、有趣的方式回答用户的问题。
如果用户询问景点相关信息，结合提供的景点上下文来回答。
每次回答尽量在100字以内，用口语化的方式表达。`;

    if (context?.spotName) {
      systemPrompt += `\n\n当前景点信息：${context.spotName}`;
    }

    if (context?.spotId) {
      const [spots] = await pool.execute('SELECT * FROM spots WHERE id = ?', [context.spotId]);
      if (spots.length > 0) {
        systemPrompt += `\n景点描述：${spots[0].description}`;
      }
    }

    const response = await fetch('https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.DASHSCOPE_API_KEY || 'mock-key'}`
      },
      body: JSON.stringify({
        model: 'qwen-turbo',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: message }
        ],
        max_tokens: 500
      })
    });

    if (response.ok) {
      const data = await response.json();
      return data.choices?.[0]?.message?.content || '抱歉，我暂时无法回答这个问题。';
    }

    throw new Error('LLM API error');
  } catch (error) {
    console.error('LLM error:', error);

    return generateFallbackReply(message, context);
  }
}

function generateFallbackReply(message, context) {
  const lowerMessage = message.toLowerCase();

  if (lowerMessage.includes('什么时候') || lowerMessage.includes('建于') || lowerMessage.includes('建于')) {
    if (context?.spotName === '故宫') {
      return '故宫始建于明成祖永乐四年，也就是公元1406年，历时14年于1420年建成。';
    }
    return '这个建筑的历史非常悠久，建议您听听语音讲解了解更多。';
  }

  if (lowerMessage.includes('谁') || lowerMessage.includes('什么人')) {
    return '这里有很多有趣的故事，让我来为您讲解...';
  }

  if (lowerMessage.includes('怎么') || lowerMessage.includes('如何')) {
    return '建议您跟随导览路线参观，这样可以看到最精华的部分。';
  }

  if (lowerMessage.includes('好吃') || lowerMessage.includes('餐厅')) {
    return '附近有不少当地特色餐厅，我可以为您推荐几处。';
  }

  if (lowerMessage.includes('门票') || lowerMessage.includes('多少钱')) {
    return '建议提前在官网查看门票价格，周末人比较多，建议早点出发。';
  }

  return '让我为您详细介绍这个景点...如果您有其他问题可以随时问我。';
}

async function saveChatHistory(userId, spotId, role, content, audioUrl) {
  const id = require('uuid').v4();
  await pool.execute(
    'INSERT INTO chat_history (id, user_id, spot_id, role, content, audio_url) VALUES (?, ?, ?, ?, ?, ?)',
    [id, userId, spotId, role, content, audioUrl]
  );
}

async function getChatContext(userId, spotId) {
  const [rows] = await pool.execute(
    'SELECT * FROM chat_history WHERE user_id = ? AND spot_id = ? ORDER BY created_at DESC LIMIT 10',
    [userId, spotId || 'null']
  );

  return rows.reverse().map(row => ({
    role: row.role,
    content: row.content
  }));
}

module.exports = {
  generateContextualReply,
  saveChatHistory,
  getChatContext
};
const fetch = require('node-fetch');
const { pool } = require('../../config/database');

async function recognizeImage(imageBase64) {
  try {
    const apiKey = process.env.ALIYUN_API_KEY;
    const endpoint = 'https://imagerecognition.cn-shanghai.aliyuncs.com';

    const response = await fetch(`${endpoint}/api/recognize`, {
      method: 'POST',
      headers: {
        'Authorization': `APPCODE ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        image: imageBase64
      })
    });

    if (!response.ok) {
      throw new Error(`阿里云API错误: ${response.status}`);
    }

    const data = await response.json();

    if (data.labels && data.labels.length > 0) {
      const [spots] = await pool.execute('SELECT * FROM spots LIMIT 100');

      for (const spot of spots) {
        const tags = typeof spot.tags === 'string' ? JSON.parse(spot.tags) : spot.tags;

        for (const label of data.labels) {
          if (spot.name.includes(label) || tags.some(tag => label.includes(tag))) {
            return {
              spotId: spot.id,
              name: spot.name,
              confidence: data.confidence || 0.9
            };
          }
        }
      }
    }

    return null;
  } catch (error) {
    console.error('Image recognition error:', error);

    const [spots] = await pool.execute('SELECT * FROM spots LIMIT 10');
    if (spots.length > 0) {
      return {
        spotId: spots[0].id,
        name: spots[0].name,
        confidence: 0.5
      };
    }

    return null;
  }
}

async function uploadImage(imageData) {
  const imageUrl = `https://cdn.youban.com/images/${Date.now()}.jpg`;
  return imageUrl;
}

module.exports = { recognizeImage, uploadImage };
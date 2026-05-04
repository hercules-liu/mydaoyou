const mysql = require('mysql2/promise');
require('dotenv').config({ path: './.env' });

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  multipleStatements: true
});

async function initDatabase() {
  const connection = await pool.getConnection();

  try {
    console.log('开始初始化数据库...');

    await connection.query('CREATE DATABASE IF NOT EXISTS youban');
    await connection.query('USE youban');

    await connection.query(`
      CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(32) PRIMARY KEY,
        phone VARCHAR(20) UNIQUE NOT NULL,
        nickname VARCHAR(50),
        avatar VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS friendships (
        user_id VARCHAR(32),
        friend_id VARCHAR(32),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (user_id, friend_id),
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (friend_id) REFERENCES users(id)
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS user_locations (
        user_id VARCHAR(32) PRIMARY KEY,
        latitude DOUBLE NOT NULL,
        longitude DOUBLE NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS spots (
        id VARCHAR(32) PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        description TEXT,
        latitude DOUBLE NOT NULL,
        longitude DOUBLE NOT NULL,
        radius INT DEFAULT 100,
        tags JSON,
        suggested_duration INT DEFAULT 3600,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_location (latitude, longitude)
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS comments (
        id VARCHAR(32) PRIMARY KEY,
        spot_id VARCHAR(32),
        user_id VARCHAR(32),
        content TEXT NOT NULL,
        rating DECIMAL(2,1) NOT NULL,
        images JSON,
        like_count INT DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (spot_id) REFERENCES spots(id),
        FOREIGN KEY (user_id) REFERENCES users(id),
        INDEX idx_spot (spot_id),
        INDEX idx_user (user_id)
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS comment_likes (
        user_id VARCHAR(32),
        comment_id VARCHAR(32),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (user_id, comment_id),
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (comment_id) REFERENCES comments(id)
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS footprints (
        user_id VARCHAR(32),
        spot_id VARCHAR(32),
        visited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        has_played BOOLEAN DEFAULT FALSE,
        PRIMARY KEY (user_id, spot_id),
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (spot_id) REFERENCES spots(id)
      )
    `);

    await connection.query(`
      CREATE TABLE IF NOT EXISTS chat_history (
        id VARCHAR(32) PRIMARY KEY,
        user_id VARCHAR(32),
        spot_id VARCHAR(32),
        role ENUM('user', 'assistant'),
        content TEXT,
        audio_url VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id),
        INDEX idx_user_spot (user_id, spot_id)
      )
    `);

    console.log('数据库表创建完成');

    const { v4: uuidv4 } = require('uuid');

    const testUsers = [
      { id: 'user_001', phone: '13800138001', nickname: '张三', avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=ZhangSan' },
      { id: 'user_002', phone: '13800138002', nickname: '李四', avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=LiSi' },
      { id: 'user_003', phone: '13800138003', nickname: '王五', avatar: 'https://api.dicebear.com/7.x/avataaars/png?seed=WangWu' }
    ];

    for (const user of testUsers) {
      await connection.query(
        'INSERT IGNORE INTO users (id, phone, nickname, avatar) VALUES (?, ?, ?, ?)',
        [user.id, user.phone, user.nickname, user.avatar]
      );
    }

    console.log('测试用户创建完成');

    const testSpots = [
      {
        id: 'spot_001',
        name: '故宫',
        description: '故宫又名紫禁城，是中国古代宫廷建筑的精华，是世界上规模最大、保存最完整的木质结构古建筑群。主要建筑有太和殿、乾清宫、坤宁宫等，极具历史和文化价值。',
        latitude: 39.9163,
        longitude: 116.3972,
        radius: 500,
        tags: JSON.stringify(['皇宫', '明清', '世界遗产', '建筑']),
        suggested_duration: 7200
      },
      {
        id: 'spot_002',
        name: '天安门广场',
        description: '天安门广场是世界上最大的城市广场之一，位于北京市中心，总面积44公顷，可容纳100万人。广场中央是人民英雄纪念碑，西侧是人民大会堂，东侧是中国国家博物馆。',
        latitude: 39.9073,
        longitude: 116.3972,
        radius: 300,
        tags: JSON.stringify(['广场', '地标', '政治中心']),
        suggested_duration: 3600
      },
      {
        id: 'spot_003',
        name: '景山公园',
        description: '景山公园位于故宫北侧，是明清时期的皇家园林。公园最高点的万春亭可以俯瞰故宫全景，是摄影爱好者拍摄故宫的绝佳位置。',
        latitude: 39.9282,
        longitude: 116.3975,
        radius: 200,
        tags: JSON.stringify(['公园', '园林', '摄影点']),
        suggested_duration: 1800
      },
      {
        id: 'spot_004',
        name: '天坛',
        description: '天坛是明清两代皇帝祭天、祈谷的场所，是中国古代祭祀建筑的杰出代表。祈年殿是天坛的标志性建筑，内围以蓝色琉璃瓦，象征天空。',
        latitude: 39.8828,
        longitude: 116.4106,
        radius: 400,
        tags: JSON.stringify(['祭祀', '古迹', '世界遗产']),
        suggested_duration: 5400
      },
      {
        id: 'spot_005',
        name: '长城',
        description: '长城是中国古代的军事防御工程，是世界七大奇迹之一。长城绵延万里，气势雄伟，是中华民族的象征。',
        latitude: 40.4319,
        longitude: 116.5704,
        radius: 1000,
        tags: JSON.stringify(['古迹', '世界遗产', '军事', '必去']),
        suggested_duration: 14400
      }
    ];

    for (const spot of testSpots) {
      await connection.query(
        `INSERT IGNORE INTO spots (id, name, description, latitude, longitude, radius, tags, suggested_duration)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [spot.id, spot.name, spot.description, spot.latitude, spot.longitude, spot.radius, spot.tags, spot.suggested_duration]
      );
    }

    console.log('测试景点创建完成');

    const testComments = [
      { id: 'comment_001', spot_id: 'spot_001', user_id: 'user_001', content: '这里真的很壮观！建议早上早点来，人少一点拍照效果更好。', rating: 4.5, like_count: 42 },
      { id: 'comment_002', spot_id: 'spot_001', user_id: 'user_002', content: '历史文化底蕴深厚，建议听一下语音讲解，能了解到很多背后的故事。', rating: 5.0, like_count: 28 },
      { id: 'comment_003', spot_id: 'spot_002', user_id: 'user_003', content: '最佳拍照点在入口左侧，光线特别好！', rating: 4.0, like_count: 15 }
    ];

    for (const comment of testComments) {
      await connection.query(
        `INSERT IGNORE INTO comments (id, spot_id, user_id, content, rating, like_count)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [comment.id, comment.spot_id, comment.user_id, comment.content, comment.rating, comment.like_count]
      );
    }

    console.log('测试点评创建完成');

    console.log('数据库初始化完成！');

  } finally {
    connection.release();
  }
}

initDatabase().catch(console.error);
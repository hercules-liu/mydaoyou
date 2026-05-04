const jwt = require('jsonwebtoken');
const { pool, redisClient } = require('../config/database');

async function authenticateSocket(socket, next) {
  try {
    const token = socket.handshake.auth.token || socket.handshake.query.token;

    if (!token) {
      return next(new Error('未授权'));
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    socket.userId = decoded.userId;
    socket.userPhone = decoded.phone;

    next();
  } catch (error) {
    next(new Error('无效Token'));
  }
}

async function handleLocationUpdate(socket, data) {
  try {
    const { lat, lng, timestamp } = data;

    await pool.execute(
      `INSERT INTO user_locations (user_id, latitude, longitude, updated_at)
       VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE latitude = ?, longitude = ?, updated_at = ?`,
      [socket.userId, lat, lng, timestamp || new Date(), lat, lng, timestamp || new Date()]
    );

    await redisClient.hSet(`user:${socket.userId}:location`, {
      latitude: lat.toString(),
      longitude: lng.toString(),
      updatedAt: new Date().toISOString()
    });
    await redisClient.expire(`user:${socket.userId}:location`, 300);

    await checkAndNotifySpotEntry(socket, lat, lng);

    await notifyFriendsLocation(socket, lat, lng);

  } catch (error) {
    console.error('Location update error:', error);
  }
}

async function checkAndNotifySpotEntry(socket, lat, lng) {
  try {
    const [spots] = await pool.execute('SELECT * FROM spots');

    for (const spot of spots) {
      const distance = calculateDistance(lat, lng, spot.latitude, spot.longitude);

      if (distance <= spot.radius) {
        const key = `user:${socket.userId}:entered:${spot.id}`;
        const alreadyEntered = await redisClient.get(key);

        if (!alreadyEntered) {
          await redisClient.set(key, '1', { EX: 3600 });

          socket.emit('spot_enter', {
            spotId: spot.id,
            name: spot.name,
            description: spot.description,
            distance: Math.round(distance)
          });
        }
      }
    }
  } catch (error) {
    console.error('Spot detection error:', error);
  }
}

async function notifyFriendsLocation(socket, userLat, userLng) {
  try {
    const [friends] = await pool.execute(`
      SELECT f.friend_id, ul.latitude, ul.longitude
      FROM friendships f
      JOIN user_locations ul ON f.friend_id = ul.user_id
      WHERE f.user_id = ?
    `, [socket.userId]);

    for (const friend of friends) {
      const distance = calculateDistance(
        userLat, userLng,
        friend.latitude, friend.longitude
      );

      socket.emit('friend_location', {
        friendId: friend.friend_id,
        latitude: friend.latitude,
        longitude: friend.longitude,
        distance: Math.round(distance)
      });
    }
  } catch (error) {
    console.error('Notify friends error:', error);
  }
}

function calculateDistance(lat1, lng1, lat2, lng2) {
  const R = 6371000;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLng/2) * Math.sin(dLng/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

module.exports = {
  authenticateSocket,
  handleLocationUpdate
};
const express = require('express');
const { pool } = require('../../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

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

router.get('/nearby', authenticate, async (req, res) => {
  try {
    const lat = parseFloat(req.query.lat);
    const lng = parseFloat(req.query.lng);
    const radius = parseInt(req.query.radius) || 5000;

    if (isNaN(lat) || isNaN(lng)) {
      return res.status(400).json({ error: '经纬度必填' });
    }

    const [spots] = await pool.execute('SELECT * FROM spots');

    const nearbySpots = spots
      .map(spot => ({
        ...spot,
        tags: typeof spot.tags === 'string' ? JSON.parse(spot.tags) : spot.tags,
        distance: calculateDistance(lat, lng, spot.latitude, spot.longitude)
      }))
      .filter(spot => spot.distance <= radius)
      .sort((a, b) => a.distance - b.distance);

    res.json(nearbySpots);
  } catch (error) {
    console.error('Get nearby spots error:', error);
    res.status(500).json({ error: '获取失败' });
  }
});

router.get('/:id', authenticate, async (req, res) => {
  try {
    const [rows] = await pool.execute('SELECT * FROM spots WHERE id = ?', [req.params.id]);

    if (rows.length === 0) {
      return res.status(404).json({ error: '景点不存在' });
    }

    const spot = rows[0];
    spot.tags = typeof spot.tags === 'string' ? JSON.parse(spot.tags) : spot.tags;

    res.json(spot);
  } catch (error) {
    console.error('Get spot error:', error);
    res.status(500).json({ error: '获取失败' });
  }
});

router.get('/search', authenticate, async (req, res) => {
  try {
    const query = req.query.q || '';

    const [rows] = await pool.execute(
      'SELECT id, name, latitude, longitude FROM spots WHERE name LIKE ? LIMIT 20',
      [`%${query}%`]
    );

    res.json(rows);
  } catch (error) {
    console.error('Search spots error:', error);
    res.status(500).json({ error: '搜索失败' });
  }
});

module.exports = router;
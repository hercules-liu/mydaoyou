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

router.get('/plan', authenticate, async (req, res) => {
  try {
    const lat = parseFloat(req.query.lat);
    const lng = parseFloat(req.query.lng);
    const maxSpots = parseInt(req.query.limit) || 5;

    if (isNaN(lat) || isNaN(lng)) {
      return res.status(400).json({ error: '经纬度必填' });
    }

    const [spots] = await pool.execute('SELECT * FROM spots');

    const spotsWithDistance = spots.map(spot => ({
      ...spot,
      tags: typeof spot.tags === 'string' ? JSON.parse(spot.tags) : spot.tags,
      distance: calculateDistance(lat, lng, spot.latitude, spot.longitude)
    }));

    spotsWithDistance.sort((a, b) => a.distance - b.distance);

    const selectedSpots = spotsWithDistance.slice(0, maxSpots);

    let totalTime = 0;
    let totalDistance = 0;

    const route = selectedSpots.map((spot, index) => {
      let walkingDistance = 0;
      let walkingTime = 0;

      if (index === 0) {
        walkingDistance = spot.distance;
      } else {
        const prev = selectedSpots[index - 1];
        walkingDistance = calculateDistance(prev.latitude, prev.longitude, spot.latitude, spot.longitude);
        totalDistance += walkingDistance;
      }

      walkingTime = walkingDistance / 80 * 60;

      const visitTime = totalTime + walkingTime;

      const node = {
        order: index + 1,
        spotId: spot.id,
        spotName: spot.name,
        spotDescription: spot.description,
        walkingDistance,
        walkingTime,
        visitTime,
        estimatedDuration: spot.suggested_duration || 3600
      };

      totalTime = visitTime + (spot.suggested_duration || 3600);

      return node;
    });

    res.json({
      route,
      summary: {
        totalSpots: route.length,
        totalDistance: Math.round(totalDistance),
        totalTimeMinutes: Math.round(totalTime / 60)
      }
    });
  } catch (error) {
    console.error('Route plan error:', error);
    res.status(500).json({ error: '规划失败' });
  }
});

module.exports = router;
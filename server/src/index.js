const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
require('dotenv').config();

const { pool, redisClient, connectRedis } = require('../config/database');
const authRoutes = require('../routes/auth');
const userRoutes = require('../routes/user');
const spotRoutes = require('../routes/spots');
const locationRoutes = require('../routes/location');
const chatRoutes = require('../routes/chat');
const commentRoutes = require('../routes/comments');
const routeRoutes = require('../routes/route');
const { authenticateSocket, handleLocationUpdate, handleSpotDetection } = require('../services/socketService');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true }));

app.use('/api/auth', authRoutes);
app.use('/api/user', userRoutes);
app.use('/api/spots', spotRoutes);
app.use('/api/location', locationRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/comments', commentRoutes);
app.use('/api/route', routeRoutes);

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

io.use(authenticateSocket);

io.on('connection', (socket) => {
  console.log('Client connected:', socket.userId);

  socket.on('location_update', async (data) => {
    await handleLocationUpdate(socket, data);
  });

  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.userId);
  });
});

const PORT = process.env.PORT || 8080;

async function startServer() {
  try {
    await connectRedis();
    console.log('Redis connected');

    const connection = await pool.getConnection();
    console.log('MySQL connected');
    connection.release();

    server.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();

module.exports = { app, server, io };
// config/redis.js
const { createClient } = require('redis');
const logger = require('../utils/logger');

const client = createClient({ url: process.env.REDIS_URL || 'redis://localhost:6379' });
client.on('error', (err) => logger.error('Redis error', { error: err.message }));
client.connect();

module.exports = client;

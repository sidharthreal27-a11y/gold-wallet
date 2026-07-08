// server.js
require('dotenv').config();
const app = require('./app');
const logger = require('./utils/logger');
const { sequelize } = require('./models');

const PORT = process.env.PORT || 4000;

async function start() {
  try {
    await sequelize.authenticate();
    logger.info('Postgres connection established.');
    app.listen(PORT, () => logger.info(`Gold Wallet API listening on :${PORT}`));
  } catch (err) {
    logger.error('Failed to start server', { error: err.message });
    process.exit(1);
  }
}

start();

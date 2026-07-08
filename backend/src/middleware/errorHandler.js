// middleware/errorHandler.js
const logger = require('../utils/logger');

module.exports = function errorHandler(err, req, res, next) {
  logger.error('Unhandled error', { error: err.message, stack: err.stack, path: req.path });
  const status = err.status || 500;
  res.status(status).json({
    error: status === 500 ? 'Internal server error' : err.message,
  });
};

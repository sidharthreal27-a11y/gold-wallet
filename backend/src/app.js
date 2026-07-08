// app.js
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const authRoutes = require('./routes/auth.routes');
const walletRoutes = require('./routes/wallets.routes');
const transactionRoutes = require('./routes/transactions.routes');
const priceRoutes = require('./routes/prices.routes');
const notificationRoutes = require('./routes/notifications.routes');
const rewardsRoutes = require('./routes/rewards.routes');
const referralRoutes = require('./routes/referrals.routes');
const adminRoutes = require('./routes/admin.routes');
const rpcProxyRoutes = require('./routes/rpcProxy.routes');

const errorHandler = require('./middleware/errorHandler');
const requestLogger = require('./middleware/requestLogger');

const app = express();

app.use(helmet());
app.use(cors({ origin: process.env.CORS_ORIGIN?.split(',') || '*' }));
app.use(express.json({ limit: '256kb' }));
app.use(requestLogger);

// Global rate limit; auth routes get a stricter limiter of their own.
app.use(
  rateLimit({
    windowMs: 60 * 1000,
    max: 120,
    standardHeaders: true,
    legacyHeaders: false,
  })
);

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/wallets', walletRoutes);
app.use('/api/v1/transactions', transactionRoutes);
app.use('/api/v1/prices', priceRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/rewards', rewardsRoutes);
app.use('/api/v1/referrals', referralRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/rpc', rpcProxyRoutes);

app.use((req, res) => res.status(404).json({ error: 'Not found' }));
app.use(errorHandler);

module.exports = app;

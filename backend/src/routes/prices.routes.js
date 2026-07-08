// routes/prices.routes.js
//
// Price data is a read-only proxy to a market-data provider (CoinGecko here),
// cached in Redis so the client isn't hammering a rate-limited third party.
// This never touches user funds — purely display data.
const express = require('express');
const router = express.Router();
const pricesController = require('../controllers/prices.controller');
const { requireAuth } = require('../middleware/auth');

router.get('/', pricesController.getPrices); // ?symbols=BTC,ETH,SOL&vs=usd,inr
router.get('/history/:symbol', pricesController.getHistory); // for charts

router.use(requireAuth);
router.get('/watchlist', pricesController.getWatchlist);
router.post('/watchlist/:symbol', pricesController.addToWatchlist);
router.delete('/watchlist/:symbol', pricesController.removeFromWatchlist);

router.get('/alerts', pricesController.getAlerts);
router.post('/alerts', pricesController.createAlert); // { symbol, targetPrice, direction: 'above'|'below' }
router.delete('/alerts/:id', pricesController.deleteAlert);

module.exports = router;

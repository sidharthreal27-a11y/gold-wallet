// controllers/prices.controller.js
const redis = require('../config/redis');
const logger = require('../utils/logger');

const COINGECKO_BASE = 'https://api.coingecko.com/api/v3';
const CACHE_TTL_SECONDS = 30;

const SYMBOL_TO_ID = {
  BTC: 'bitcoin',
  ETH: 'ethereum',
  BNB: 'binancecoin',
  MATIC: 'matic-network',
  SOL: 'solana',
  USDT: 'tether',
  USDC: 'usd-coin',
  XRP: 'ripple',
  LTC: 'litecoin',
  DOGE: 'dogecoin',
};

exports.getPrices = async (req, res, next) => {
  try {
    const symbols = (req.query.symbols || 'BTC,ETH,BNB,MATIC,SOL,USDT,USDC,XRP,LTC,DOGE')
      .split(',')
      .map((s) => s.trim().toUpperCase());
    const vsCurrencies = (req.query.vs || 'usd,inr').split(',');

    const cacheKey = `prices:${symbols.join(',')}:${vsCurrencies.join(',')}`;
    const cached = await redis.get(cacheKey);
    if (cached) return res.json(JSON.parse(cached));

    const ids = symbols.map((s) => SYMBOL_TO_ID[s]).filter(Boolean).join(',');
    const url = `${COINGECKO_BASE}/simple/price?ids=${ids}&vs_currencies=${vsCurrencies.join(',')}&include_24hr_change=true`;
    const response = await fetch(url);
    if (!response.ok) throw new Error(`CoinGecko responded ${response.status}`);
    const data = await response.json();

    // Re-key by our own symbols so the client doesn't need CoinGecko's id map.
    const result = {};
    for (const symbol of symbols) {
      const id = SYMBOL_TO_ID[symbol];
      if (id && data[id]) result[symbol] = data[id];
    }

    await redis.set(cacheKey, JSON.stringify(result), 'EX', CACHE_TTL_SECONDS);
    res.json(result);
  } catch (err) {
    logger.error('getPrices failed', { error: err.message });
    next(err);
  }
};

exports.getHistory = async (req, res, next) => {
  try {
    const { symbol } = req.params;
    const days = req.query.days || '7';
    const vs = req.query.vs || 'usd';
    const id = SYMBOL_TO_ID[symbol.toUpperCase()];
    if (!id) return res.status(400).json({ error: 'Unsupported symbol' });

    const cacheKey = `price_history:${id}:${days}:${vs}`;
    const cached = await redis.get(cacheKey);
    if (cached) return res.json(JSON.parse(cached));

    const url = `${COINGECKO_BASE}/coins/${id}/market_chart?vs_currency=${vs}&days=${days}`;
    const response = await fetch(url);
    if (!response.ok) throw new Error(`CoinGecko responded ${response.status}`);
    const data = await response.json();

    await redis.set(cacheKey, JSON.stringify(data), 'EX', 300); // 5 min cache for chart data
    res.json(data);
  } catch (err) {
    next(err);
  }
};

// --- Watchlist (per-user, stored in Postgres via a simple JSON column or
// dedicated table — using Redis set here for brevity; swap for a Watchlist
// model + table in production so it survives cache eviction) ---

exports.getWatchlist = async (req, res, next) => {
  try {
    const members = await redis.sMembers(`watchlist:${req.user.id}`);
    res.json({ symbols: members });
  } catch (err) {
    next(err);
  }
};

exports.addToWatchlist = async (req, res, next) => {
  try {
    await redis.sAdd(`watchlist:${req.user.id}`, req.params.symbol.toUpperCase());
    res.status(201).json({ ok: true });
  } catch (err) {
    next(err);
  }
};

exports.removeFromWatchlist = async (req, res, next) => {
  try {
    await redis.sRem(`watchlist:${req.user.id}`, req.params.symbol.toUpperCase());
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
};

// --- Price alerts: persisted, checked by a background job (see
// jobs/priceAlertChecker.job.js) that pushes a notification when triggered. ---
const { PriceAlert } = require('../models');

exports.getAlerts = async (req, res, next) => {
  try {
    const alerts = await PriceAlert.findAll({ where: { userId: req.user.id } });
    res.json(alerts);
  } catch (err) {
    next(err);
  }
};

exports.createAlert = async (req, res, next) => {
  try {
    const { symbol, targetPrice, direction } = req.body;
    if (!symbol || !targetPrice || !['above', 'below'].includes(direction)) {
      return res.status(400).json({ error: 'symbol, targetPrice, direction(above|below) required' });
    }
    const alert = await PriceAlert.create({
      userId: req.user.id,
      symbol: symbol.toUpperCase(),
      targetPrice,
      direction,
      status: 'active',
    });
    res.status(201).json(alert);
  } catch (err) {
    next(err);
  }
};

exports.deleteAlert = async (req, res, next) => {
  try {
    await PriceAlert.destroy({ where: { id: req.params.id, userId: req.user.id } });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
};

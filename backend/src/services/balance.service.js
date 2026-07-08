// services/balance.service.js
const redis = require('../config/redis');
const rpcService = require('./rpc.service');

const CACHE_TTL_SECONDS = 15;

async function getCachedBalance(address, chainId) {
  const cacheKey = `balance:${chainId}:${address}`;
  const cached = await redis.get(cacheKey);
  if (cached) return cached;

  const weiHex = await rpcService.rawCall(chainId, 'eth_getBalance', [address, 'latest']);
  const wei = BigInt(weiHex).toString();
  await redis.set(cacheKey, wei, 'EX', CACHE_TTL_SECONDS);
  return wei;
}

module.exports = { getCachedBalance };

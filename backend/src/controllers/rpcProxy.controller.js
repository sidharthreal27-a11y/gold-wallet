// controllers/rpcProxy.controller.js
//
// Strict allowlist of read-only JSON-RPC methods. Nothing that could move
// funds (eth_sendTransaction, eth_sendRawTransaction, personal_sign, etc.)
// is reachable through this proxy — raw signed broadcasts go through the
// dedicated /transactions/broadcast route where they're logged distinctly.
const rpcService = require('../services/rpc.service');

const ALLOWED_METHODS = new Set([
  'eth_getBalance',
  'eth_gasPrice',
  'eth_getTransactionCount',
  'eth_estimateGas',
  'eth_getTransactionReceipt',
  'eth_blockNumber',
  'eth_call', // for ERC-20 balanceOf reads
]);

exports.forwardReadOnlyCall = async (req, res, next) => {
  try {
    const { method, params } = req.body;
    if (!ALLOWED_METHODS.has(method)) {
      return res.status(403).json({ error: `Method ${method} is not permitted through this proxy` });
    }
    const result = await rpcService.rawCall(req.params.chainId, method, params);
    res.json({ result });
  } catch (err) { next(err); }
};

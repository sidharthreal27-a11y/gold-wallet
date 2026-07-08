// services/rpc.service.js
// Thin wrapper around chain RPC endpoints for read calls + raw broadcast.
const CHAIN_RPC_URLS = {
  1: `https://mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
  56: process.env.BNB_RPC_URL,
  137: `https://polygon-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_POLYGON_KEY}`,
};

async function rawCall(chainId, method, params = []) {
  const url = CHAIN_RPC_URLS[chainId];
  if (!url) throw new Error(`Unsupported chainId ${chainId}`);
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ jsonrpc: '2.0', id: 1, method, params }),
  });
  const data = await response.json();
  if (data.error) throw new Error(data.error.message);
  return data.result;
}

async function broadcastRaw(chainId, signedTxHex) {
  return rawCall(chainId, 'eth_sendRawTransaction', [signedTxHex]);
}

async function getTransactionStatus(chainId, txHash) {
  const receipt = await rawCall(chainId, 'eth_getTransactionReceipt', [txHash]);
  if (!receipt) return { status: 'pending' };
  return { status: receipt.status === '0x1' ? 'confirmed' : 'failed', blockNumber: receipt.blockNumber };
}

module.exports = { rawCall, broadcastRaw, getTransactionStatus };

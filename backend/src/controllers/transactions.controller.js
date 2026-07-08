// controllers/transactions.controller.js
const { TransactionRecord, WalletAddress } = require('../models');
const rpcService = require('../services/rpc.service');

exports.getHistory = async (req, res, next) => {
  try {
    const wallets = await WalletAddress.findAll({ where: { userId: req.user.id } });
    const walletIds = wallets.map((w) => w.id);
    const txs = await TransactionRecord.findAll({
      where: { walletAddressId: walletIds },
      order: [['createdAt', 'DESC']],
      limit: 100,
    });
    res.json(txs);
  } catch (err) { next(err); }
};

// Client has already built AND SIGNED the transaction on-device. This
// endpoint is a pure relay to the chain's RPC node — it never has access
// to, and cannot reconstruct, the private key that produced the signature.
exports.broadcastSignedTransaction = async (req, res, next) => {
  try {
    const { chainId, signedTxHex } = req.body;
    if (!chainId || !signedTxHex) {
      return res.status(400).json({ error: 'chainId and signedTxHex required' });
    }
    const txHash = await rpcService.broadcastRaw(chainId, signedTxHex);
    res.status(202).json({ txHash });
  } catch (err) { next(err); }
};

exports.getStatus = async (req, res, next) => {
  try {
    const status = await rpcService.getTransactionStatus(req.query.chainId, req.params.txHash);
    res.json(status);
  } catch (err) { next(err); }
};

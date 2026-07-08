// controllers/wallets.controller.js
const { WalletAddress } = require('../models');
const { getCachedBalance } = require('../services/balance.service');

exports.listWallets = async (req, res, next) => {
  try {
    const wallets = await WalletAddress.findAll({ where: { userId: req.user.id } });
    res.json(wallets);
  } catch (err) { next(err); }
};

exports.registerWalletAddress = async (req, res, next) => {
  try {
    const { address, chainId, label, accountIndex } = req.body;
    if (!address || !chainId) return res.status(400).json({ error: 'address and chainId required' });
    const wallet = await WalletAddress.create({
      userId: req.user.id, address, chainId, label, accountIndex: accountIndex ?? 0,
    });
    res.status(201).json(wallet);
  } catch (err) { next(err); }
};

exports.updateWalletLabel = async (req, res, next) => {
  try {
    const [count] = await WalletAddress.update(
      { label: req.body.label },
      { where: { id: req.params.id, userId: req.user.id } }
    );
    if (!count) return res.status(404).json({ error: 'Not found' });
    res.json({ ok: true });
  } catch (err) { next(err); }
};

exports.removeWallet = async (req, res, next) => {
  try {
    await WalletAddress.destroy({ where: { id: req.params.id, userId: req.user.id } });
    res.json({ ok: true });
  } catch (err) { next(err); }
};

exports.getBalance = async (req, res, next) => {
  try {
    const wallet = await WalletAddress.findOne({ where: { id: req.params.id, userId: req.user.id } });
    if (!wallet) return res.status(404).json({ error: 'Not found' });
    const balance = await getCachedBalance(wallet.address, wallet.chainId);
    res.json({ address: wallet.address, chainId: wallet.chainId, balance });
  } catch (err) { next(err); }
};

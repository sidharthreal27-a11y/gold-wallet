// routes/wallets.routes.js
//
// IMPORTANT: this router only ever accepts/returns PUBLIC addresses. There is
// no endpoint here that accepts a private key or mnemonic — that would defeat
// the entire non-custodial design. Client derives keys locally and only
// registers the resulting public address here (for balance lookups, labels,
// and notification targeting).
const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/wallets.controller');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);
router.get('/', ctrl.listWallets);
router.post('/', ctrl.registerWalletAddress); // { address, chainId, label, accountIndex }
router.patch('/:id', ctrl.updateWalletLabel);
router.delete('/:id', ctrl.removeWallet);
router.get('/:id/balance', ctrl.getBalance); // proxies to chain RPC / indexer, read-only

module.exports = router;

// routes/rpcProxy.routes.js
//
// Optional: lets the mobile client make read-only RPC calls (balance, gas
// price, nonce) through the backend instead of embedding a paid provider key
// (Infura/Alchemy) directly in the shipped APK, where it could be extracted
// via decompilation. This proxy only forwards allow-listed read methods —
// it never accepts or relays a private key, and eth_sendRawTransaction goes
// through /transactions/broadcast instead, where it's logged distinctly.
const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/rpcProxy.controller');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);
router.post('/:chainId', ctrl.forwardReadOnlyCall); // body: { method, params } — method must be in allowlist

module.exports = router;

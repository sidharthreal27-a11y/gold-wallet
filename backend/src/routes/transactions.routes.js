// routes/transactions.routes.js
//
// Read-only history + a broadcast-relay endpoint that accepts an ALREADY
// SIGNED raw transaction from the client and forwards it to the chain RPC.
// The server never builds or signs a transaction on the user's behalf.
const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/transactions.controller');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);
router.get('/', ctrl.getHistory);
router.post('/broadcast', ctrl.broadcastSignedTransaction); // { chainId, signedTxHex }
router.get('/:txHash/status', ctrl.getStatus);

module.exports = router;

// routes/referrals.routes.js
const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/referrals.controller');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);
router.get('/my-code', ctrl.getMyCode);
router.get('/my-referrals', ctrl.listMyReferrals);
router.post('/redeem', ctrl.redeemCode); // { code } — applied once at signup normally

module.exports = router;

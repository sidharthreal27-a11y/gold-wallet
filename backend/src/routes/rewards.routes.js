// routes/rewards.routes.js
const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/rewards.controller');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);
router.get('/balance', ctrl.getBalance);
router.get('/history', ctrl.getLedger);

module.exports = router;

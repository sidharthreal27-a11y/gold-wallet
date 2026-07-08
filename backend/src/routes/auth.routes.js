// routes/auth.routes.js
const express = require('express');
const rateLimit = require('express-rate-limit');
const router = express.Router();
const ctrl = require('../controllers/auth.controller');

const authLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 10 }); // brute-force guard

router.post('/signup', authLimiter, ctrl.signup);
router.post('/login', authLimiter, ctrl.login);
router.post('/refresh', ctrl.refresh);
router.post('/logout', ctrl.logout);
router.post('/2fa/enable', ctrl.enable2fa);
router.post('/2fa/verify', ctrl.verify2fa);

module.exports = router;

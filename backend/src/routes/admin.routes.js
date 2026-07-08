// routes/admin.routes.js
//
// Admin can manage USERS (suspend, view metadata) and REWARD RULES
// (create/edit point-award rules), and view aggregate analytics.
// Admin CANNOT view private keys (none exist server-side), CANNOT move
// user funds, and CANNOT directly credit arbitrary point balances outside
// of the rule-based ledger — every grant still goes through RewardLedgerEntry
// with a rule reference, so it's auditable rather than a free-form edit.
const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/admin.controller');
const { requireAuth, requireAdmin } = require('../middleware/auth');

router.use(requireAuth, requireAdmin);

router.get('/users', ctrl.listUsers);
router.patch('/users/:id/status', ctrl.updateUserStatus); // suspend/reactivate

router.get('/reward-rules', ctrl.listRewardRules);
router.post('/reward-rules', ctrl.createRewardRule);
router.patch('/reward-rules/:id', ctrl.updateRewardRule);

router.get('/analytics/overview', ctrl.getAnalyticsOverview);

module.exports = router;

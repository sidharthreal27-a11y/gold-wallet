// routes/notifications.routes.js
const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/notifications.controller');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);
router.get('/', ctrl.list);
router.post('/register-device', ctrl.registerDevice); // FCM/APNs token
router.patch('/:id/read', ctrl.markRead);

module.exports = router;

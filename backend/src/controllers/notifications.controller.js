// controllers/notifications.controller.js
const { Notification } = require('../models');

exports.list = async (req, res, next) => {
  try {
    const notifications = await Notification.findAll({
      where: { userId: req.user.id },
      order: [['createdAt', 'DESC']],
      limit: 50,
    });
    res.json(notifications);
  } catch (err) { next(err); }
};

exports.registerDevice = async (req, res, next) => {
  try {
    const { fcmToken, platform } = req.body;
    // Persist to a DeviceToken table (omitted for brevity) keyed by userId,
    // used by services/push.service.js when sending FCM/APNs pushes.
    res.json({ ok: true });
  } catch (err) { next(err); }
};

exports.markRead = async (req, res, next) => {
  try {
    await Notification.update(
      { readAt: new Date() },
      { where: { id: req.params.id, userId: req.user.id } }
    );
    res.json({ ok: true });
  } catch (err) { next(err); }
};

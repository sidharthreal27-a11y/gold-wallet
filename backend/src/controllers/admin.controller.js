// controllers/admin.controller.js
//
// Every mutation here is scoped to user status and reward-rule configuration
// only. There is no endpoint to view a user's keys (none stored) or to
// directly increment a user's point balance outside of the rule engine.
const { User, RewardRule, sequelize } = require('../models');

exports.listUsers = async (req, res, next) => {
  try {
    const { limit = 50, offset = 0, search } = req.query;
    const where = search ? { email: { [require('sequelize').Op.iLike]: `%${search}%` } } : {};
    const users = await User.findAndCountAll({
      where,
      attributes: ['id', 'email', 'role', 'status', 'pointsBalance', 'createdAt', 'lastLoginAt'],
      limit: Number(limit),
      offset: Number(offset),
      order: [['createdAt', 'DESC']],
    });
    res.json(users);
  } catch (err) { next(err); }
};

exports.updateUserStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    if (!['active', 'suspended'].includes(status)) {
      return res.status(400).json({ error: 'status must be active or suspended' });
    }
    await User.update({ status }, { where: { id: req.params.id } });
    res.json({ ok: true });
  } catch (err) { next(err); }
};

exports.listRewardRules = async (req, res, next) => {
  try {
    res.json(await RewardRule.findAll());
  } catch (err) { next(err); }
};

exports.createRewardRule = async (req, res, next) => {
  try {
    const { key, description, pointsAwarded, maxPerUser } = req.body;
    const rule = await RewardRule.create({ key, description, pointsAwarded, maxPerUser });
    res.status(201).json(rule);
  } catch (err) { next(err); }
};

exports.updateRewardRule = async (req, res, next) => {
  try {
    const [count] = await RewardRule.update(req.body, { where: { id: req.params.id } });
    if (!count) return res.status(404).json({ error: 'Not found' });
    res.json({ ok: true });
  } catch (err) { next(err); }
};

exports.getAnalyticsOverview = async (req, res, next) => {
  try {
    const [totalUsers] = await sequelize.query('SELECT COUNT(*)::int AS count FROM users');
    const [activeToday] = await sequelize.query(
      `SELECT COUNT(*)::int AS count FROM users WHERE "lastLoginAt" > NOW() - INTERVAL '1 day'`
    );
    res.json({
      totalUsers: totalUsers[0].count,
      activeToday: activeToday[0].count,
    });
  } catch (err) { next(err); }
};

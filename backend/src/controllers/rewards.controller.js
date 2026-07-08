// controllers/rewards.controller.js
const { User, RewardLedgerEntry, RewardRule } = require('../models');

exports.getBalance = async (req, res, next) => {
  try {
    const user = await User.findByPk(req.user.id, { attributes: ['pointsBalance'] });
    res.json({ pointsBalance: user.pointsBalance });
  } catch (err) { next(err); }
};

exports.getLedger = async (req, res, next) => {
  try {
    const entries = await RewardLedgerEntry.findAll({
      where: { userId: req.user.id },
      include: [{ model: RewardRule, attributes: ['key', 'description'] }],
      order: [['createdAt', 'DESC']],
      limit: 100,
    });
    res.json(entries);
  } catch (err) { next(err); }
};

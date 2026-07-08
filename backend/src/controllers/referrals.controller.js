// controllers/referrals.controller.js
const { User, Referral } = require('../models');
const { grantReward } = require('../services/rewards.service');

exports.getMyCode = async (req, res, next) => {
  try {
    const user = await User.findByPk(req.user.id, { attributes: ['referralCode'] });
    res.json({ code: user.referralCode });
  } catch (err) { next(err); }
};

exports.listMyReferrals = async (req, res, next) => {
  try {
    const referrals = await Referral.findAll({ where: { referrerId: req.user.id } });
    res.json(referrals);
  } catch (err) { next(err); }
};

exports.redeemCode = async (req, res, next) => {
  try {
    const { code } = req.body;
    const referrer = await User.findOne({ where: { referralCode: code } });
    if (!referrer || referrer.id === req.user.id) {
      return res.status(400).json({ error: 'Invalid referral code' });
    }
    const existing = await Referral.findOne({ where: { refereeId: req.user.id } });
    if (existing) return res.status(409).json({ error: 'Referral already applied to this account' });

    const referral = await Referral.create({
      referrerId: referrer.id, refereeId: req.user.id, status: 'pending',
    });
    // Reward is granted later, once the referee meets a qualifying action
    // (e.g. first real on-chain transaction), not immediately at signup —
    // this avoids paying out for throwaway/bot signups.
    res.status(201).json(referral);
  } catch (err) { next(err); }
};

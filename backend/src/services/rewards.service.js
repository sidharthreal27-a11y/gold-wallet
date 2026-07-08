// services/rewards.service.js
//
// The ONLY way points are ever added to a user. Always goes through a named
// RewardRule so every grant is auditable and rate-limited (maxPerUser), never
// an arbitrary balance write from an ad-hoc admin action.
const { sequelize, User, RewardRule, RewardLedgerEntry } = require('../models');

async function grantReward({ userId, ruleKey, triggerEvent }) {
  return sequelize.transaction(async (t) => {
    const rule = await RewardRule.findOne({ where: { key: ruleKey, active: true }, transaction: t });
    if (!rule) return null;

    if (rule.maxPerUser != null) {
      const count = await RewardLedgerEntry.count({
        where: { userId, ruleId: rule.id }, transaction: t,
      });
      if (count >= rule.maxPerUser) return null; // cap reached, silently skip
    }

    await RewardLedgerEntry.create(
      { userId, ruleId: rule.id, points: rule.pointsAwarded, triggerEvent },
      { transaction: t }
    );
    await User.increment('pointsBalance', { by: rule.pointsAwarded, where: { id: userId }, transaction: t });
    return rule.pointsAwarded;
  });
}

module.exports = { grantReward };

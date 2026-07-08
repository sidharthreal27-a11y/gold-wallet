// models/rewardRule.model.js
// Rules are transparent, published, event-triggered point awards (e.g.
// "10 points per referral signup", "5 points for first transaction") —
// never arbitrary balance edits. All grants are logged in RewardLedgerEntry
// so every point awarded traces back to a specific rule + trigger event.
module.exports = (sequelize, DataTypes) => {
  const RewardRule = sequelize.define('RewardRule', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    key: { type: DataTypes.STRING, allowNull: false, unique: true }, // e.g. 'referral_signup'
    description: { type: DataTypes.STRING, allowNull: false },
    pointsAwarded: { type: DataTypes.INTEGER, allowNull: false },
    active: { type: DataTypes.BOOLEAN, defaultValue: true },
    maxPerUser: { type: DataTypes.INTEGER }, // null = unlimited
  }, { tableName: 'reward_rules', timestamps: true });
  return RewardRule;
};

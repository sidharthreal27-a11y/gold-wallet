// models/rewardLedgerEntry.model.js
// Append-only ledger — points balance on User is a derived cache, this table
// is the source of truth and is never edited after insert (only inserted).
module.exports = (sequelize, DataTypes) => {
  const RewardLedgerEntry = sequelize.define('RewardLedgerEntry', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    userId: { type: DataTypes.UUID, allowNull: false },
    ruleId: { type: DataTypes.UUID, allowNull: false },
    points: { type: DataTypes.INTEGER, allowNull: false },
    triggerEvent: { type: DataTypes.STRING, allowNull: false }, // e.g. 'referral:abc123'
  }, { tableName: 'reward_ledger_entries', timestamps: true, updatedAt: false });
  return RewardLedgerEntry;
};

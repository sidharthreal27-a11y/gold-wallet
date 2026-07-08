// models/referral.model.js
module.exports = (sequelize, DataTypes) => {
  const Referral = sequelize.define('Referral', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    referrerId: { type: DataTypes.UUID, allowNull: false },
    refereeId: { type: DataTypes.UUID, allowNull: false, unique: true },
    status: { type: DataTypes.ENUM('pending', 'qualified', 'rewarded'), defaultValue: 'pending' },
  }, { tableName: 'referrals', timestamps: true });
  return Referral;
};

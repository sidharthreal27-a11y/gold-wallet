// models/index.js
const { Sequelize, DataTypes } = require('sequelize');

const sequelize = new Sequelize(process.env.DATABASE_URL, {
  dialect: 'postgres',
  logging: false,
  pool: { max: 10, min: 0, idle: 10000 },
});

const User = require('./user.model')(sequelize, DataTypes);
const WalletAddress = require('./walletAddress.model')(sequelize, DataTypes);
const Notification = require('./notification.model')(sequelize, DataTypes);
const RewardRule = require('./rewardRule.model')(sequelize, DataTypes);
const RewardLedgerEntry = require('./rewardLedgerEntry.model')(sequelize, DataTypes);
const Referral = require('./referral.model')(sequelize, DataTypes);
const TransactionRecord = require('./transactionRecord.model')(sequelize, DataTypes);
const RefreshToken = require('./refreshToken.model')(sequelize, DataTypes);
const PriceAlert = require('./priceAlert.model')(sequelize, DataTypes);

// --- Associations ---
User.hasMany(WalletAddress, { foreignKey: 'userId', as: 'wallets' });
WalletAddress.belongsTo(User, { foreignKey: 'userId' });

User.hasMany(Notification, { foreignKey: 'userId', as: 'notifications' });
Notification.belongsTo(User, { foreignKey: 'userId' });

User.hasMany(RewardLedgerEntry, { foreignKey: 'userId', as: 'rewardEntries' });
RewardLedgerEntry.belongsTo(User, { foreignKey: 'userId' });
RewardLedgerEntry.belongsTo(RewardRule, { foreignKey: 'ruleId' });

User.hasMany(Referral, { foreignKey: 'referrerId', as: 'referralsMade' });
User.hasOne(Referral, { foreignKey: 'refereeId', as: 'referredBy' });

WalletAddress.hasMany(TransactionRecord, { foreignKey: 'walletAddressId', as: 'transactions' });
TransactionRecord.belongsTo(WalletAddress, { foreignKey: 'walletAddressId' });

User.hasMany(RefreshToken, { foreignKey: 'userId' });
RefreshToken.belongsTo(User, { foreignKey: 'userId' });

User.hasMany(PriceAlert, { foreignKey: 'userId' });
PriceAlert.belongsTo(User, { foreignKey: 'userId' });

module.exports = {
  sequelize,
  User,
  WalletAddress,
  Notification,
  RewardRule,
  RewardLedgerEntry,
  Referral,
  TransactionRecord,
  RefreshToken,
  PriceAlert,
};

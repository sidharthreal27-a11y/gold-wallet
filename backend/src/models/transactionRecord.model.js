// models/transactionRecord.model.js
// Cached mirror of on-chain transactions for fast history display + push
// notifications. This is a READ cache populated by indexer/webhook jobs —
// it is never the system of record for balances, and nothing here can move
// funds; it only stores what the chain already confirmed.
module.exports = (sequelize, DataTypes) => {
  const TransactionRecord = sequelize.define('TransactionRecord', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    walletAddressId: { type: DataTypes.UUID, allowNull: false },
    txHash: { type: DataTypes.STRING, allowNull: false },
    chainId: { type: DataTypes.INTEGER, allowNull: false },
    direction: { type: DataTypes.ENUM('in', 'out'), allowNull: false },
    counterpartyAddress: { type: DataTypes.STRING },
    assetSymbol: { type: DataTypes.STRING, allowNull: false },
    amount: { type: DataTypes.DECIMAL(36, 18), allowNull: false },
    status: { type: DataTypes.ENUM('pending', 'confirmed', 'failed'), defaultValue: 'pending' },
    confirmations: { type: DataTypes.INTEGER, defaultValue: 0 },
    blockNumber: { type: DataTypes.BIGINT },
  }, {
    tableName: 'transaction_records',
    timestamps: true,
    indexes: [{ unique: true, fields: ['txHash', 'chainId'] }],
  });
  return TransactionRecord;
};

// models/walletAddress.model.js
//
// This table stores PUBLIC addresses only — enough to fetch balances, tag a
// label ("My main wallet"), enable notifications for incoming transfers, and
// attribute reward points. There is no field here that could hold a private
// key or mnemonic, by design.
module.exports = (sequelize, DataTypes) => {
  const WalletAddress = sequelize.define(
    'WalletAddress',
    {
      id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
      userId: { type: DataTypes.UUID, allowNull: false },
      address: { type: DataTypes.STRING, allowNull: false }, // checksummed public address
      chainId: { type: DataTypes.INTEGER, allowNull: false }, // 1=ETH, 56=BNB, 137=Polygon
      label: { type: DataTypes.STRING, defaultValue: 'My Wallet' },
      accountIndex: { type: DataTypes.INTEGER, defaultValue: 0 }, // BIP44 index, for display only
      isPrimary: { type: DataTypes.BOOLEAN, defaultValue: false },
    },
    {
      tableName: 'wallet_addresses',
      timestamps: true,
      indexes: [
        { unique: true, fields: ['userId', 'address', 'chainId'] },
        { fields: ['address'] },
      ],
    }
  );

  return WalletAddress;
};

// models/user.model.js
//
// NOTE: this table intentionally has no column for private keys, seed
// phrases, or anything key-derived. Only email/auth + profile + role.
module.exports = (sequelize, DataTypes) => {
  const User = sequelize.define(
    'User',
    {
      id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
      email: { type: DataTypes.STRING, allowNull: false, unique: true },
      passwordHash: { type: DataTypes.STRING, allowNull: false }, // argon2id hash
      displayName: { type: DataTypes.STRING },
      role: {
        type: DataTypes.ENUM('user', 'admin', 'support'),
        defaultValue: 'user',
      },
      status: {
        type: DataTypes.ENUM('active', 'suspended', 'deleted'),
        defaultValue: 'active',
      },
      emailVerifiedAt: { type: DataTypes.DATE },
      totpSecretEncrypted: { type: DataTypes.STRING }, // server-side 2FA secret, AES-encrypted at rest
      totpEnabled: { type: DataTypes.BOOLEAN, defaultValue: false },
      referralCode: { type: DataTypes.STRING, unique: true },
      pointsBalance: { type: DataTypes.INTEGER, defaultValue: 0 },
      lastLoginAt: { type: DataTypes.DATE },
      lastLoginIp: { type: DataTypes.STRING },
    },
    {
      tableName: 'users',
      timestamps: true,
      indexes: [{ fields: ['referralCode'] }, { fields: ['email'] }],
    }
  );

  return User;
};

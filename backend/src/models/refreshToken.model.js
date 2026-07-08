// models/refreshToken.model.js
module.exports = (sequelize, DataTypes) => {
  const RefreshToken = sequelize.define('RefreshToken', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    userId: { type: DataTypes.UUID, allowNull: false },
    tokenHash: { type: DataTypes.STRING, allowNull: false }, // SHA-256 of refresh token, never plaintext
    deviceInfo: { type: DataTypes.STRING },
    expiresAt: { type: DataTypes.DATE, allowNull: false },
    revokedAt: { type: DataTypes.DATE },
  }, { tableName: 'refresh_tokens', timestamps: true });
  return RefreshToken;
};

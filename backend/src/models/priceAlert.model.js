// models/priceAlert.model.js
module.exports = (sequelize, DataTypes) => {
  const PriceAlert = sequelize.define(
    'PriceAlert',
    {
      id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
      userId: { type: DataTypes.UUID, allowNull: false },
      symbol: { type: DataTypes.STRING, allowNull: false },
      targetPrice: { type: DataTypes.DECIMAL(24, 8), allowNull: false },
      direction: { type: DataTypes.ENUM('above', 'below'), allowNull: false },
      status: { type: DataTypes.ENUM('active', 'triggered', 'cancelled'), defaultValue: 'active' },
      triggeredAt: { type: DataTypes.DATE },
    },
    { tableName: 'price_alerts', timestamps: true }
  );
  return PriceAlert;
};

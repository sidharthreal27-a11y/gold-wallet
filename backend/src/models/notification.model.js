// models/notification.model.js
module.exports = (sequelize, DataTypes) => {
  const Notification = sequelize.define('Notification', {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    userId: { type: DataTypes.UUID, allowNull: false },
    type: { type: DataTypes.ENUM('tx_incoming', 'tx_confirmed', 'price_alert', 'reward', 'system'), allowNull: false },
    title: { type: DataTypes.STRING, allowNull: false },
    body: { type: DataTypes.TEXT },
    metadata: { type: DataTypes.JSONB, defaultValue: {} },
    readAt: { type: DataTypes.DATE },
  }, { tableName: 'notifications', timestamps: true });
  return Notification;
};

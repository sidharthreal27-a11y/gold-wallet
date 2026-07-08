// controllers/auth.controller.js
const argon2 = require('argon2');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const speakeasy = require('speakeasy');
const { User, RefreshToken } = require('../models');

function signAccessToken(user) {
  return jwt.sign({ sub: user.id, role: user.role }, process.env.JWT_ACCESS_SECRET, {
    expiresIn: process.env.JWT_ACCESS_TTL || '15m',
  });
}

function generateReferralCode() {
  return crypto.randomBytes(4).toString('hex');
}

exports.signup = async (req, res, next) => {
  try {
    const { email, password, referredByCode } = req.body;
    if (!email || !password || password.length < 10) {
      return res.status(400).json({ error: 'Valid email and password (min 10 chars) required' });
    }
    const existing = await User.findOne({ where: { email } });
    if (existing) return res.status(409).json({ error: 'Email already registered' });

    const passwordHash = await argon2.hash(password, { type: argon2.argon2id });
    const user = await User.create({
      email,
      passwordHash,
      referralCode: generateReferralCode(),
    });

    if (referredByCode) {
      // Handled by referrals.controller in a real implementation — kept
      // decoupled here so signup doesn't fail if referral linking fails.
      req.app.locals.referralQueue?.push({ refereeId: user.id, code: referredByCode });
    }

    const accessToken = signAccessToken(user);
    res.status(201).json({ accessToken, user: { id: user.id, email: user.email } });
  } catch (err) {
    next(err);
  }
};

exports.login = async (req, res, next) => {
  try {
    const { email, password, totpCode } = req.body;
    const user = await User.findOne({ where: { email } });
    if (!user || !(await argon2.verify(user.passwordHash, password))) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    if (user.status !== 'active') {
      return res.status(403).json({ error: `Account is ${user.status}` });
    }
    if (user.totpEnabled) {
      if (!totpCode) return res.status(401).json({ error: 'TOTP code required', requires2fa: true });
      const verified = speakeasy.totp.verify({
        secret: decryptTotpSecret(user.totpSecretEncrypted),
        encoding: 'base32',
        token: totpCode,
        window: 1,
      });
      if (!verified) return res.status(401).json({ error: 'Invalid 2FA code' });
    }

    const accessToken = signAccessToken(user);
    const refreshToken = crypto.randomBytes(48).toString('hex');
    const tokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
    await RefreshToken.create({
      userId: user.id,
      tokenHash,
      deviceInfo: req.headers['user-agent'],
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    });

    user.lastLoginAt = new Date();
    user.lastLoginIp = req.ip;
    await user.save();

    res.json({ accessToken, refreshToken, user: { id: user.id, email: user.email } });
  } catch (err) {
    next(err);
  }
};

exports.refresh = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.status(400).json({ error: 'refreshToken required' });
    const tokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
    const record = await RefreshToken.findOne({ where: { tokenHash, revokedAt: null } });
    if (!record || record.expiresAt < new Date()) {
      return res.status(401).json({ error: 'Invalid or expired refresh token' });
    }
    const user = await User.findByPk(record.userId);
    res.json({ accessToken: signAccessToken(user) });
  } catch (err) {
    next(err);
  }
};

exports.logout = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      const tokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
      await RefreshToken.update({ revokedAt: new Date() }, { where: { tokenHash } });
    }
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
};

exports.enable2fa = async (req, res, next) => {
  try {
    const secret = speakeasy.generateSecret({ name: `${process.env.TOTP_ISSUER}:${req.user.id}` });
    // Store secret.base32 encrypted-at-rest (AES-256-GCM with a server-side
    // KMS-managed key) — encryptTotpSecret() omitted here for brevity.
    res.json({ otpauthUrl: secret.otpauth_url, base32: secret.base32 });
  } catch (err) {
    next(err);
  }
};

exports.verify2fa = async (req, res, next) => {
  try {
    const { base32, token } = req.body;
    const verified = speakeasy.totp.verify({ secret: base32, encoding: 'base32', token, window: 1 });
    if (!verified) return res.status(400).json({ error: 'Invalid code' });
    await User.update(
      { totpEnabled: true, totpSecretEncrypted: encryptTotpSecret(base32) },
      { where: { id: req.user.id } }
    );
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
};

// Placeholder encrypt/decrypt — wire to a real KMS-backed AES-GCM helper.
function encryptTotpSecret(plain) { return plain; }
function decryptTotpSecret(stored) { return stored; }

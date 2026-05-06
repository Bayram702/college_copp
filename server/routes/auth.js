const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');
const { getJwtSecret } = require('../config/security');
const { getBearerToken, verifyToken } = require('../middleware/auth');
const { createRateLimiter, publicError } = require('../middleware/security');

const ALLOWED_ROLES = ['admin', 'college_rep'];
const loginLimiter = createRateLimiter({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: 'Слишком много попыток входа. Попробуйте позже.'
});

const buildUserPayload = (user) => ({
  id: user.id,
  login: user.login,
  email: user.email,
  name: user.name,
  role: {
    id: user.role_id,
    name: user.role_name,
    description: user.role_description
  },
  collegeId: user.college_id
});

const signToken = (user) => jwt.sign(
  {
    userId: user.id,
    login: user.login,
    roleId: user.role_id,
    roleName: user.role_name,
    collegeId: user.college_id
  },
  getJwtSecret(),
  { expiresIn: '24h' }
);

router.post('/login', loginLimiter, async (req, res) => {
  try {
    const username = String(req.body.username || '').replace(/[^A-Za-z0-9_]/g, '').slice(0, 50);
    const { password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ success: false, error: 'Введите логин и пароль' });
    }

    if (username.length < 3 || typeof password !== 'string' || password.length > 100) {
      return res.status(400).json({ success: false, error: 'Проверьте логин и пароль' });
    }

    const result = await db.query(`
      SELECT
        u.id,
        u.login,
        u.email,
        u.password_hash,
        u.name,
        u.role_id,
        u.college_id,
        u.status,
        r.name as role_name,
        r.description as role_description
      FROM users u
      JOIN roles r ON u.role_id = r.id
      WHERE u.login = $1
    `, [username]);

    if (result.rows.length === 0) {
      return res.status(401).json({ success: false, error: 'Неверный логин или пароль' });
    }

    const user = result.rows[0];

    if (!ALLOWED_ROLES.includes(user.role_name)) {
      return res.status(403).json({ success: false, error: 'Эта роль больше не поддерживается' });
    }

    if (user.status !== 'active') {
      return res.status(401).json({ success: false, error: 'Аккаунт не активен' });
    }

    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({ success: false, error: 'Неверный логин или пароль' });
    }

    await db.query('UPDATE users SET last_login_at = CURRENT_TIMESTAMP WHERE id = $1', [user.id]);

    res.json({
      success: true,
      data: {
        user: buildUserPayload(user),
        token: signToken(user)
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ success: false, error: publicError });
  }
});

router.post('/logout', async (req, res) => {
  res.json({ success: true });
});

router.get('/me', async (req, res) => {
  try {
    const token = getBearerToken(req);
    if (!token) {
      return res.status(401).json({ success: false, error: 'Токен не предоставлен' });
    }

    const decoded = verifyToken(token);
    const result = await db.query(`
      SELECT
        u.id,
        u.login,
        u.email,
        u.name,
        u.role_id,
        u.college_id,
        u.status,
        r.name as role_name,
        r.description as role_description
      FROM users u
      JOIN roles r ON u.role_id = r.id
      WHERE u.id = $1
    `, [decoded.userId]);

    if (result.rows.length === 0) {
      return res.status(401).json({ success: false, error: 'Пользователь не найден' });
    }

    const user = result.rows[0];
    if (!ALLOWED_ROLES.includes(user.role_name)) {
      return res.status(403).json({ success: false, error: 'Эта роль больше не поддерживается' });
    }

    if (user.status !== 'active') {
      return res.status(401).json({ success: false, error: 'Аккаунт не активен' });
    }

    res.json({ success: true, data: { user: buildUserPayload(user) } });
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, error: 'Срок действия токена истек' });
    }
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ success: false, error: 'Недействительный токен' });
    }

    console.error('Auth check error:', error);
    res.status(401).json({ success: false, error: 'Недействительный токен' });
  }
});

module.exports = router;

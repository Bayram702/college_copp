const jwt = require('jsonwebtoken')
const db = require('../db')
const { getJwtSecret } = require('../config/security')

const verifyToken = (token) => jwt.verify(token, getJwtSecret())

const getBearerToken = (req) => {
  const [scheme, token] = String(req.headers.authorization || '').split(' ')
  if (scheme !== 'Bearer' || !token) return null
  return token
}

const requireAuth = async (req, res, next) => {
  try {
    const token = getBearerToken(req)
    if (!token) {
      return res.status(401).json({ success: false, error: 'Требуется авторизация' })
    }

    const decoded = verifyToken(token)
    const userId = decoded.userId || decoded.id
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Недействительный токен' })
    }

    const result = await db.query(
      `
        SELECT
          u.id,
          u.login,
          u.role_id,
          u.college_id,
          u.status,
          r.name as role_name
        FROM users u
        JOIN roles r ON u.role_id = r.id
        WHERE u.id = $1
      `,
      [userId]
    )

    if (result.rows.length === 0 || result.rows[0].status !== 'active') {
      return res.status(401).json({ success: false, error: 'Аккаунт не активен' })
    }

    const user = result.rows[0]
    req.user = {
      userId: user.id,
      id: user.id,
      login: user.login,
      roleId: user.role_id,
      roleName: user.role_name,
      collegeId: user.college_id
    }

    await db.query('UPDATE users SET last_login_at = CURRENT_TIMESTAMP WHERE id = $1', [userId])
    next()
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, error: 'Сессия истекла' })
    }
    return res.status(401).json({ success: false, error: 'Недействительный токен' })
  }
}

const requireRole = (...roles) => (req, res, next) => {
  if (!req.user || !roles.includes(req.user.roleName)) {
    return res.status(403).json({ success: false, error: 'Доступ запрещен' })
  }
  next()
}

const requireCollegeBinding = (req, res, next) => {
  if (!req.user?.collegeId) {
    return res.status(403).json({ success: false, error: 'Колледж не привязан к пользователю' })
  }
  next()
}

module.exports = {
  getBearerToken,
  verifyToken,
  requireAuth,
  requireRole,
  requireCollegeBinding
}

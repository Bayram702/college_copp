const jwt = require('jsonwebtoken')
const { getJwtSecret } = require('../config/security')

const verifyToken = (token) => jwt.verify(token, getJwtSecret())

const getBearerToken = (req) => {
  const [scheme, token] = String(req.headers.authorization || '').split(' ')
  if (scheme !== 'Bearer' || !token) return null
  return token
}

const requireAuth = (req, res, next) => {
  try {
    const token = getBearerToken(req)
    if (!token) {
      return res.status(401).json({ success: false, error: 'Требуется авторизация' })
    }

    req.user = verifyToken(token)
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

module.exports = {
  getBearerToken,
  verifyToken,
  requireAuth,
  requireRole
}

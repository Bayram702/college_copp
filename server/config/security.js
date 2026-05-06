const crypto = require('crypto')

const isProduction = process.env.NODE_ENV === 'production'

const splitList = (value) => String(value || '')
  .split(',')
  .map((item) => item.trim())
  .filter(Boolean)

const allowedOrigins = splitList(process.env.CORS_ORIGINS)

const devOrigins = [
  'http://localhost:5173',
  'http://127.0.0.1:5173',
  'http://localhost:4173',
  'http://127.0.0.1:4173'
]

const getAllowedOrigins = () => {
  if (allowedOrigins.length) return allowedOrigins
  return isProduction ? [] : devOrigins
}

const getJwtSecret = () => {
  const secret = process.env.JWT_SECRET

  if (isProduction) {
    if (!secret || secret.length < 32 || secret === 'your-secret-key') {
      throw new Error('JWT_SECRET must be set to a strong value in production')
    }
    return secret
  }

  return secret || 'dev-only-change-me'
}

const createJwtSecret = () => crypto.randomBytes(48).toString('hex')

module.exports = {
  isProduction,
  getAllowedOrigins,
  getJwtSecret,
  createJwtSecret
}

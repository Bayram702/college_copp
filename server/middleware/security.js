const cors = require('cors')
const { getAllowedOrigins, isProduction } = require('../config/security')

const publicError = 'Ошибка сервера'

const corsOptions = {
  origin(origin, callback) {
    const allowedOrigins = getAllowedOrigins()

    if (!origin) return callback(null, true)
    if (allowedOrigins.includes(origin)) return callback(null, true)

    return callback(new Error('CORS origin is not allowed'))
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}

const applySecurityHeaders = (req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff')
  res.setHeader('X-Frame-Options', 'DENY')
  res.setHeader('Referrer-Policy', 'no-referrer')
  res.setHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()')

  if (isProduction) {
    res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains')
  }

  next()
}

const enforceHttps = (req, res, next) => {
  if (process.env.FORCE_HTTPS !== 'true') return next()

  const forwardedProto = req.headers['x-forwarded-proto']
  if (req.secure || forwardedProto === 'https') return next()

  return res.redirect(308, `https://${req.headers.host}${req.originalUrl}`)
}

const createRateLimiter = ({ windowMs, max, message }) => {
  const buckets = new Map()

  return (req, res, next) => {
    const now = Date.now()
    const key = req.ip || req.headers['x-forwarded-for'] || 'unknown'
    const bucket = buckets.get(key) || { count: 0, resetAt: now + windowMs }

    if (bucket.resetAt <= now) {
      bucket.count = 0
      bucket.resetAt = now + windowMs
    }

    bucket.count += 1
    buckets.set(key, bucket)

    if (bucket.count > max) {
      res.setHeader('Retry-After', Math.ceil((bucket.resetAt - now) / 1000))
      return res.status(429).json({ success: false, error: message })
    }

    next()
  }
}

const notFoundHandler = (req, res) => {
  res.status(404).json({ success: false, error: 'Маршрут не найден' })
}

const errorHandler = (err, req, res, next) => {
  if (res.headersSent) return next(err)

  if (err.message === 'CORS origin is not allowed') {
    return res.status(403).json({ success: false, error: 'Источник запроса запрещен' })
  }

  console.error('Unhandled server error:', err)
  return res.status(500).json({ success: false, error: publicError })
}

module.exports = {
  corsMiddleware: cors(corsOptions),
  applySecurityHeaders,
  enforceHttps,
  createRateLimiter,
  notFoundHandler,
  errorHandler,
  publicError
}

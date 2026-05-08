import { API_URL } from './api'

const SERVER_URL = API_URL.replace(/\/api\/?$/, '')

export const resolveImageUrl = (url, fallback = '/college_stub.svg') => {
  if (!url) return fallback
  if (/^https?:\/\//i.test(url) || url.startsWith('data:')) return url
  if (url.startsWith('/uploads/')) return `${SERVER_URL}${url}`
  return url
}

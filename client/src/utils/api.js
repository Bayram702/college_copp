export const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api'

export const apiPath = (path) => `${API_URL}${path.startsWith('/') ? path : `/${path}`}`

export const trimText = (value) => (typeof value === 'string' ? value.trim() : value)

export const maskRussianPhone = (value) => {
  const digits = String(value || '').replace(/\D/g, '').replace(/^8/, '7')
  const normalized = digits.startsWith('7') ? digits.slice(1, 11) : digits.slice(0, 10)
  let result = '+7'
  if (normalized.length > 0) result += ` (${normalized.slice(0, 3)}`
  if (normalized.length >= 3) result += ')'
  if (normalized.length > 3) result += ` ${normalized.slice(3, 6)}`
  if (normalized.length > 6) result += `-${normalized.slice(6, 8)}`
  if (normalized.length > 8) result += `-${normalized.slice(8, 10)}`
  return result
}

const isBlank = (value) => value === undefined || value === null || trimText(value) === ''
const isEmail = (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
const isPhone = (value) => /^\+7 \(\d{3}\) \d{3}-\d{2}-\d{2}$/.test(value)
const isUrl = (value) => /^https?:\/\/[^\s/$.?#].[^\s]*$/i.test(value)
const isLogin = (value) => /^[A-Za-z0-9_]{3,50}$/.test(value)
const isSpecialtyCode = (value) => /^\d{2}\.\d{2}\.\d{2}(\.\d{2})?$/.test(value)

export const normalizeUrl = (value) => {
  const cleaned = trimText(value)
  if (!cleaned) return ''
  return /^https?:\/\//i.test(cleaned) ? cleaned : `https://${cleaned}`
}

const intInRange = (value, min = 0, max = 10000) => {
  const number = Number(value)
  return Number.isInteger(number) && number >= min && number <= max
}

const scoreInRange = (value) => {
  const raw = String(value ?? 0)
  const number = Number(value)
  return Number.isFinite(number) && number >= 0 && number <= 5 && /^\d+(\.\d)?$/.test(raw)
}

export const firstError = (errors) => Object.values(errors)[0] || ''

export const validateCollege = (form) => {
  const errors = {}
  if (isBlank(form.name)) errors.name = 'Название колледжа обязательно'
  else if (trimText(form.name).length < 3 || trimText(form.name).length > 255) errors.name = 'Название: от 3 до 255 символов'
  if (form.short_name && trimText(form.short_name).length > 50) errors.short_name = 'Краткое название: максимум 50 символов'
  if (form.description && trimText(form.description).length > 3000) errors.description = 'Описание: максимум 3000 символов'
  if (form.phone && !isPhone(form.phone)) errors.phone = 'Телефон: +7 (999) 999-99-99'
  if (form.email && (!isEmail(form.email) || form.email.length > 255)) errors.email = 'Укажите корректный email'
  if (form.website && (!isUrl(normalizeUrl(form.website)) || normalizeUrl(form.website).length > 255)) errors.website = 'Укажите корректный URL'
  if (form.social_vk && (!isUrl(normalizeUrl(form.social_vk)) || normalizeUrl(form.social_vk).length > 255)) errors.social_vk = 'Укажите корректный URL'
  if (form.social_max && (!isUrl(normalizeUrl(form.social_max)) || normalizeUrl(form.social_max).length > 255)) errors.social_max = 'Укажите корректный URL'
  if (!intInRange(form.budget_places)) errors.budget_places = 'Бюджетные места: целое число 0-10000'
  if (!intInRange(form.commercial_places)) errors.commercial_places = 'Коммерческие места: целое число 0-10000'
  if (!scoreInRange(form.avg_score)) errors.avg_score = 'Средний балл: 0-5, максимум 1 знак после запятой'
  if (!scoreInRange(form.min_score)) errors.min_score = 'Минимальный балл: 0-5, максимум 1 знак после запятой'
  if (!['active', 'inactive'].includes(form.status)) errors.status = 'Недопустимый статус'
  return errors
}

export const normalizeCollege = (form) => ({
  ...form,
  name: trimText(form.name),
  short_name: trimText(form.short_name || ''),
  description: trimText(form.description || ''),
  phone: trimText(form.phone || ''),
  email: trimText(form.email || ''),
  website: normalizeUrl(form.website),
  social_vk: normalizeUrl(form.social_vk),
  social_max: normalizeUrl(form.social_max),
  professionalitet_cluster: trimText(form.professionalitet_cluster || '')
})

export const validateRepresentative = (form, { editing = false } = {}) => {
  const errors = {}
  if (isBlank(form.name) || trimText(form.name).length < 2 || trimText(form.name).length > 255) errors.name = 'ФИО: от 2 до 255 символов'
  if (isBlank(form.login) || !isLogin(trimText(form.login))) errors.login = 'Логин: латиница, цифры и _, 3-50 символов'
  if (isBlank(form.email) || !isEmail(trimText(form.email)) || trimText(form.email).length > 255) errors.email = 'Укажите корректный email'
  if (form.phone && !isPhone(form.phone)) errors.phone = 'Телефон: +7 (999) 999-99-99'
  if (!editing && (!form.password || form.password.length < 6 || form.password.length > 100)) errors.password = 'Пароль: от 6 до 100 символов'
  if (editing && form.password && (form.password.length < 6 || form.password.length > 100)) errors.password = 'Новый пароль: от 6 до 100 символов'
  if (!['active', 'inactive'].includes(form.status)) errors.status = 'Недопустимый статус'
  return errors
}

export const normalizeRepresentative = (form) => {
  const collegeId = form.college_id || null
  return {
    ...form,
    name: trimText(form.name),
    login: trimText(form.login),
    email: trimText(form.email),
    phone: trimText(form.phone || ''),
    role: 'college_rep',
    college_id: collegeId,
    status: collegeId ? form.status : 'inactive'
  }
}

export const validateSpecialty = (form) => {
  const errors = {}
  if (isBlank(form.code) || !isSpecialtyCode(trimText(form.code))) errors.code = 'Код: 00.00.00 или 00.00.00.00'
  if (isBlank(form.name) || trimText(form.name).length < 3 || trimText(form.name).length > 255) errors.name = 'Название: от 3 до 255 символов'
  if (form.description && trimText(form.description).length > 3000) errors.description = 'Описание: максимум 3000 символов'
  if (form.duration && trimText(form.duration).length > 100) errors.duration = 'Срок обучения: максимум 100 символов'
  if (form.qualification && trimText(form.qualification).length > 255) errors.qualification = 'Квалификация: максимум 255 символов'
  if (!['full-time', 'part-time', 'distance'].includes(form.form)) errors.form = 'Недопустимая форма обучения'
  if (!['9', '11'].includes(String(form.base_education))) errors.base_education = 'Базовое образование: 9 или 11'
  if (!intInRange(form.budget_places)) errors.budget_places = 'Бюджетные места: целое число 0-10000'
  if (!intInRange(form.commercial_places)) errors.commercial_places = 'Коммерческие места: целое число 0-10000'
  if (!intInRange(form.price_per_year, 0, 10000000)) errors.price_per_year = 'Стоимость: целое число от 0'
  if (!scoreInRange(form.avg_score)) errors.avg_score = 'Проходной балл: 0-5, максимум 1 знак после запятой'
  if (!['active', 'inactive', 'draft'].includes(form.status)) errors.status = 'Недопустимый статус'
  return errors
}

export const normalizeSpecialty = (form) => ({
  ...form,
  code: trimText(form.code),
  name: trimText(form.name),
  description: trimText(form.description || ''),
  qualification: trimText(form.qualification || ''),
  duration: trimText(form.duration || ''),
  exams: trimText(form.exams || '')
})

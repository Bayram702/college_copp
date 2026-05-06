const STATUS_VALUES = ['active', 'inactive']
const COLLEGE_STATUS_VALUES = ['active', 'inactive']
const SPECIALTY_STATUS_VALUES = ['active', 'inactive', 'draft']
const EDUCATION_FORMS = ['full-time', 'part-time', 'distance']
const BASE_EDUCATION_VALUES = ['9', '11']

const trim = (value) => (typeof value === 'string' ? value.trim() : value)
const isBlank = (value) => value === undefined || value === null || trim(value) === ''
const isEmail = (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
const isPhone = (value) => /^\+7 \(\d{3}\) \d{3}-\d{2}-\d{2}$/.test(value)
const isUrl = (value) => /^https?:\/\/[^\s/$.?#].[^\s]*$/i.test(value)
const isLogin = (value) => /^[A-Za-z0-9_]{3,50}$/.test(value)
const isSpecialtyCode = (value) => /^\d{2}\.\d{2}\.\d{2}(\.\d{2})?$/.test(value)

const normalizeUrl = (value) => {
  const cleaned = trim(value)
  if (!cleaned) return ''
  if (/^https?:\/\//i.test(cleaned)) return cleaned
  return `https://${cleaned}`
}

const parseInteger = (value) => {
  if (value === '' || value === null || value === undefined) return 0
  const number = Number(value)
  return Number.isInteger(number) ? number : NaN
}

const parseScore = (value) => {
  if (value === '' || value === null || value === undefined) return 0
  const number = Number(value)
  return Number.isFinite(number) ? Number(number.toFixed(1)) : NaN
}

const addLengthError = (errors, field, value, label, { min, max }) => {
  const cleaned = trim(value) || ''
  if (min !== undefined && cleaned.length < min) errors[field] = `${label}: минимум ${min} символа`
  if (max !== undefined && cleaned.length > max) errors[field] = `${label}: максимум ${max} символов`
}

const validateIntegerRange = (errors, field, value, label, min = 0, max = 10000) => {
  const number = parseInteger(value)
  if (!Number.isInteger(number) || number < min || number > max) {
    errors[field] = `${label}: целое число от ${min} до ${max}`
  }
  return number
}

const validateScore = (errors, field, value, label) => {
  const number = parseScore(value)
  if (!Number.isFinite(number) || number < 0 || number > 5 || !/^\d+(\.\d)?$/.test(String(value ?? 0))) {
    errors[field] = `${label}: число от 0 до 5, максимум 1 знак после запятой`
  }
  return number
}

const validationResponse = (res, errors) => {
  const firstError = Object.values(errors)[0] || 'Проверьте заполнение формы'
  return res.status(400).json({ success: false, error: firstError, errors })
}

const validateCollegePayload = (payload) => {
  const errors = {}
  const data = {
    name: trim(payload.name),
    short_name: trim(payload.short_name ?? payload.shortName ?? ''),
    description: trim(payload.description ?? ''),
    phone: trim(payload.phone ?? ''),
    email: trim(payload.email ?? ''),
    website: normalizeUrl(payload.website),
    status: trim(payload.status || 'active'),
    social_vk: normalizeUrl(payload.social_vk),
    social_max: normalizeUrl(payload.social_max),
    social_other: payload.social_other,
    budget_places: validateIntegerRange(errors, 'budget_places', payload.budget_places, 'Бюджетные места'),
    commercial_places: validateIntegerRange(errors, 'commercial_places', payload.commercial_places, 'Коммерческие места'),
    avg_score: validateScore(errors, 'avg_score', payload.avg_score, 'Средний балл'),
    min_score: validateScore(errors, 'min_score', payload.min_score, 'Минимальный балл'),
    is_professionalitet: payload.is_professionalitet === true || payload.is_professionalitet === 'true' || payload.is_professionalitet === 'yes',
    professionalitet_cluster: trim(payload.professionalitet_cluster ?? ''),
    logo_image_url: trim(payload.logo_image_url ?? ''),
    opportunities: payload.opportunities,
    employers: payload.employers,
    workshops: payload.workshops,
    professions: payload.professions,
    ovz_programs: payload.ovz_programs
  }

  if (isBlank(data.name)) errors.name = 'Название колледжа обязательно'
  else addLengthError(errors, 'name', data.name, 'Название колледжа', { min: 3, max: 255 })
  addLengthError(errors, 'short_name', data.short_name, 'Краткое название', { max: 50 })
  addLengthError(errors, 'description', data.description, 'Описание', { max: 3000 })
  if (data.phone && !isPhone(data.phone)) errors.phone = 'Телефон должен быть в формате +7 (999) 999-99-99'
  if (data.email && (!isEmail(data.email) || data.email.length > 255)) errors.email = 'Укажите корректный email до 255 символов'
  if (data.website && (!isUrl(data.website) || data.website.length > 255)) errors.website = 'Сайт должен быть корректной ссылкой http:// или https:// до 255 символов'
  if (data.social_vk && (!isUrl(data.social_vk) || data.social_vk.length > 255)) errors.social_vk = 'VK должен быть корректной ссылкой до 255 символов'
  if (data.social_max && (!isUrl(data.social_max) || data.social_max.length > 255)) errors.social_max = 'MAX должен быть корректной ссылкой до 255 символов'
  if (!COLLEGE_STATUS_VALUES.includes(data.status)) errors.status = 'Недопустимый статус колледжа'
  addLengthError(errors, 'professionalitet_cluster', data.professionalitet_cluster, 'Кластер Профессионалитета', { max: 255 })

  return { data, errors }
}

const validateRepresentativePayload = (payload, { create = true } = {}) => {
  const errors = {}
  const data = {
    name: trim(payload.name),
    login: trim(payload.login),
    email: trim(payload.email),
    phone: trim(payload.phone ?? ''),
    password: payload.password,
    role: trim(payload.role),
    status: trim(payload.status || 'active'),
    college_id: payload.college_id ?? payload.collegeId
  }
  if (isBlank(data.college_id)) {
    data.college_id = null
    data.status = 'inactive'
  } else {
    data.college_id = Number(data.college_id)
  }

  if (isBlank(data.name)) errors.name = 'ФИО обязательно'
  else addLengthError(errors, 'name', data.name, 'ФИО', { min: 2, max: 255 })
  if (isBlank(data.login) || !isLogin(data.login)) errors.login = 'Логин: латиница, цифры и _, от 3 до 50 символов'
  if (isBlank(data.email) || !isEmail(data.email) || data.email.length > 255) errors.email = 'Укажите корректный email до 255 символов'
  if (data.phone && !isPhone(data.phone)) errors.phone = 'Телефон должен быть в формате +7 (999) 999-99-99'
  if (create && (typeof data.password !== 'string' || data.password.length < 6 || data.password.length > 100)) {
    errors.password = 'Пароль: от 6 до 100 символов'
  }
  if (!create && data.password && (data.password.length < 6 || data.password.length > 100)) {
    errors.password = 'Новый пароль: от 6 до 100 символов'
  }
  if (data.role !== 'college_rep') errors.role = 'Можно создавать только представителей колледжа'
  if (data.college_id !== null && (!Number.isInteger(data.college_id) || data.college_id <= 0)) errors.college_id = 'Выберите корректный колледж'
  if (!STATUS_VALUES.includes(data.status)) errors.status = 'Недопустимый статус пользователя'

  return { data, errors }
}

const validateSpecialtyPayload = (payload) => {
  const errors = {}
  const data = {
    name: trim(payload.name),
    code: trim(payload.code),
    description: trim(payload.description ?? ''),
    qualification: trim(payload.qualification ?? ''),
    duration: trim(payload.duration ?? ''),
    base_education: trim(payload.base_education || '9'),
    form: trim(payload.form || 'full-time'),
    exams: trim(payload.exams ?? ''),
    budget_places: validateIntegerRange(errors, 'budget_places', payload.budget_places, 'Бюджетные места'),
    commercial_places: validateIntegerRange(errors, 'commercial_places', payload.commercial_places, 'Коммерческие места'),
    price_per_year: validateIntegerRange(errors, 'price_per_year', payload.price_per_year, 'Стоимость обучения', 0, 10000000),
    avg_score: validateScore(errors, 'avg_score', payload.avg_score, 'Проходной балл'),
    status: trim(payload.status || 'active')
  }

  if (isBlank(data.code) || !isSpecialtyCode(data.code)) errors.code = 'Код специальности должен быть в формате 00.00.00 или 00.00.00.00'
  if (isBlank(data.name)) errors.name = 'Название специальности обязательно'
  else addLengthError(errors, 'name', data.name, 'Название специальности', { min: 3, max: 255 })
  addLengthError(errors, 'description', data.description, 'Описание', { max: 3000 })
  addLengthError(errors, 'duration', data.duration, 'Срок обучения', { max: 100 })
  addLengthError(errors, 'qualification', data.qualification, 'Квалификация', { max: 255 })
  if (!EDUCATION_FORMS.includes(data.form)) errors.form = 'Недопустимая форма обучения'
  if (!BASE_EDUCATION_VALUES.includes(data.base_education)) errors.base_education = 'Базовое образование должно быть 9 или 11'
  if (!SPECIALTY_STATUS_VALUES.includes(data.status)) errors.status = 'Недопустимый статус специальности'

  return { data, errors }
}

module.exports = {
  validationResponse,
  validateCollegePayload,
  validateRepresentativePayload,
  validateSpecialtyPayload
}

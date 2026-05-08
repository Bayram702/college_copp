const STATUS_VALUES = ['active', 'inactive']
const COLLEGE_STATUS_VALUES = ['active', 'inactive']
const SPECIALTY_STATUS_VALUES = ['active', 'inactive', 'draft']
const EDUCATION_FORMS = ['full-time', 'part-time', 'distance']
const BASE_EDUCATION_VALUES = ['9', '11']
const ADDRESS_TYPE_VALUES = ['legal', 'actual', 'educational', 'branch', 'other']

const trim = (value) => (typeof value === 'string' ? value.trim().replace(/\s+/g, ' ') : value)
const trimMultiline = (value) => (typeof value === 'string'
  ? value.replace(/\r\n/g, '\n').replace(/[^\S\n]+/g, ' ').trim()
  : value)
const isBlank = (value) => value === undefined || value === null || trim(value) === ''
const isEmail = (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
const isPhone = (value) => /^\+7 \(\d{3}\) \d{3}-\d{2}-\d{2}$/.test(value)
const isUrl = (value) => /^https?:\/\/[^\s/$.?#].[^\s]*$/i.test(value)
const isLogin = (value) => /^[A-Za-z0-9_]{3,50}$/.test(value)
const isSpecialtyCode = (value) => /^\d{2}\.\d{2}\.\d{2}(\.\d{2})?$/.test(value)
const hasUnsafeText = (value) => /[<>{}\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/.test(String(value || ''))
const isCoordinates = (value) => /^-?\d{1,2}(\.\d+)?,\s*-?\d{1,3}(\.\d+)?$/.test(value)

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

const cleanText = (value, max = 255) => String(value || '')
  .replace(/[\u0000-\u001f\u007f<>]/g, '')
  .replace(/\s+/g, ' ')
  .slice(0, max)

const cleanMultiline = (value, max = 3000) => String(value || '')
  .replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f<>]/g, '')
  .replace(/[^\S\n]+/g, ' ')
  .slice(0, max)

const cleanEmail = (value) => String(value || '').trim().toLowerCase().replace(/\s/g, '').slice(0, 255)
const cleanUrl = (value) => String(value || '').trim().replace(/\s/g, '').slice(0, 255)
const cleanLogin = (value) => String(value || '').replace(/[^A-Za-z0-9_]/g, '').slice(0, 50)

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

const validateSafeText = (errors, field, value, label) => {
  if (hasUnsafeText(value)) errors[field] = `${label}: нельзя использовать HTML-теги и служебные символы`
}

const normalizeStringArray = (value) => {
  if (!value) return []
  if (Array.isArray(value)) return value.map((item) => cleanUrl(item)).filter(Boolean).slice(0, 20)
  if (typeof value === 'string') return value.split('\n').map((item) => cleanUrl(item)).filter(Boolean).slice(0, 20)
  return []
}

const normalizeTextArray = (value) => {
  if (!value) return []
  const list = Array.isArray(value) ? value : String(value).split('\n')
  return list.map((item) => trim(cleanText(item, 255))).filter(Boolean).slice(0, 50)
}

const validateTextList = (errors, field, list, label) => {
  if (list.length > 50) errors[field] = `${label}: максимум 50 строк`
  list.forEach((item, index) => {
    if (hasUnsafeText(item) || item.length > 255) errors[field] = `${label}: строка ${index + 1} некорректна`
  })
}

const validateUrlList = (errors, field, list, label) => {
  if (list.length > 20) errors[field] = `${label}: максимум 20 ссылок`
  list.forEach((item, index) => {
    const url = normalizeUrl(item)
    if (url && (!isUrl(url) || url.length > 255)) errors[field] = `${label}: ссылка ${index + 1} некорректна`
  })
}

const validationResponse = (res, errors) => {
  const firstError = Object.values(errors)[0] || 'Проверьте заполнение формы'
  return res.status(400).json({ success: false, error: firstError, errors })
}

const validateCollegePayload = (payload) => {
  const errors = {}
  const data = {
    name: trim(cleanText(payload.name, 255)),
    short_name: trim(payload.short_name ?? payload.shortName ?? ''),
    description: trimMultiline(cleanMultiline(payload.description ?? '', 3000)),
    phone: trim(payload.phone ?? ''),
    email: cleanEmail(payload.email ?? ''),
    website: normalizeUrl(cleanUrl(payload.website)),
    status: trim(payload.status || 'active'),
    social_vk: normalizeUrl(cleanUrl(payload.social_vk)),
    social_max: normalizeUrl(cleanUrl(payload.social_max)),
    social_other: normalizeStringArray(payload.social_other),
    budget_places: validateIntegerRange(errors, 'budget_places', payload.budget_places, 'Бюджетные места'),
    commercial_places: validateIntegerRange(errors, 'commercial_places', payload.commercial_places, 'Коммерческие места'),
    avg_score: validateScore(errors, 'avg_score', payload.avg_score, 'Средний балл'),
    min_score: validateScore(errors, 'min_score', payload.min_score, 'Минимальный балл'),
    is_professionalitet: payload.is_professionalitet === true || payload.is_professionalitet === 'true' || payload.is_professionalitet === 'yes',
    professionalitet_cluster: trim(cleanText(payload.professionalitet_cluster ?? '', 255)),
    logo_image_url: trim(payload.logo_image_url ?? ''),
    opportunities: normalizeTextArray(payload.opportunities),
    employers: normalizeTextArray(payload.employers),
    workshops: normalizeTextArray(payload.workshops),
    professions: normalizeTextArray(payload.professions),
    ovz_programs: normalizeTextArray(payload.ovz_programs)
  }

  if (isBlank(data.name)) errors.name = 'Название колледжа обязательно'
  else addLengthError(errors, 'name', data.name, 'Название колледжа', { min: 3, max: 255 })
  validateSafeText(errors, 'name', payload.name, 'Название колледжа')
  addLengthError(errors, 'short_name', data.short_name, 'Краткое название', { max: 50 })
  addLengthError(errors, 'description', data.description, 'Описание', { max: 3000 })
  validateSafeText(errors, 'description', payload.description, 'Описание')
  if (data.phone && !isPhone(data.phone)) errors.phone = 'Телефон должен быть в формате +7 (999) 999-99-99'
  if (data.email && (!isEmail(data.email) || data.email.length > 255)) errors.email = 'Укажите корректный email до 255 символов'
  if (data.website && (!isUrl(data.website) || data.website.length > 255)) errors.website = 'Сайт должен быть корректной ссылкой http:// или https:// до 255 символов'
  if (data.social_vk && (!isUrl(data.social_vk) || data.social_vk.length > 255)) errors.social_vk = 'VK должен быть корректной ссылкой до 255 символов'
  if (data.social_max && (!isUrl(data.social_max) || data.social_max.length > 255)) errors.social_max = 'MAX должен быть корректной ссылкой до 255 символов'
  validateUrlList(errors, 'social_other', data.social_other, 'Другие источники')
  if (!COLLEGE_STATUS_VALUES.includes(data.status)) errors.status = 'Недопустимый статус колледжа'
  addLengthError(errors, 'professionalitet_cluster', data.professionalitet_cluster, 'Кластер Профессионалитета', { max: 255 })
  validateSafeText(errors, 'professionalitet_cluster', payload.professionalitet_cluster, 'Кластер Профессионалитета')
  validateTextList(errors, 'opportunities', data.opportunities, 'Возможности')
  validateTextList(errors, 'employers', data.employers, 'Работодатели')
  validateTextList(errors, 'workshops', data.workshops, 'Мастерские')
  validateTextList(errors, 'professions', data.professions, 'Профессии')
  validateTextList(errors, 'ovz_programs', data.ovz_programs, 'Программы ОВЗ')

  return { data, errors }
}

const validateRepresentativePayload = (payload, { create = true } = {}) => {
  const errors = {}
  const data = {
    name: trim(cleanText(payload.name, 255)),
    login: cleanLogin(payload.login),
    email: cleanEmail(payload.email),
    phone: trim(payload.phone ?? ''),
    password: payload.password,
    role: trim(payload.role),
    status: trim(payload.status || 'active'),
    college_id: payload.college_id ?? payload.collegeId
  }
  if (isBlank(data.college_id)) {
    data.college_id = null
  } else {
    data.college_id = Number(data.college_id)
  }
  if (data.role === 'admin') data.college_id = null
  if (data.role === 'college_rep' && data.college_id === null) data.status = 'inactive'

  if (isBlank(data.name)) errors.name = 'ФИО обязательно'
  else addLengthError(errors, 'name', data.name, 'ФИО', { min: 2, max: 255 })
  validateSafeText(errors, 'name', payload.name, 'ФИО')
  if (isBlank(data.login) || !isLogin(data.login)) errors.login = 'Логин: латиница, цифры и _, от 3 до 50 символов'
  if (isBlank(data.email) || !isEmail(data.email) || data.email.length > 255) errors.email = 'Укажите корректный email до 255 символов'
  if (data.phone && !isPhone(data.phone)) errors.phone = 'Телефон должен быть в формате +7 (999) 999-99-99'
  if (create && (typeof data.password !== 'string' || data.password.length < 8 || data.password.length > 100)) {
    errors.password = 'Пароль: от 8 до 100 символов'
  }
  if (!create && data.password && (data.password.length < 8 || data.password.length > 100)) {
    errors.password = 'Новый пароль: от 8 до 100 символов'
  }
  if (!['admin', 'college_rep'].includes(data.role)) errors.role = 'Недопустимая роль'
  if (data.college_id !== null && (!Number.isInteger(data.college_id) || data.college_id <= 0)) errors.college_id = 'Выберите корректный колледж'
  if (!STATUS_VALUES.includes(data.status)) errors.status = 'Недопустимый статус пользователя'

  return { data, errors }
}

const validateSpecialtyPayload = (payload) => {
  const errors = {}
  const data = {
    name: trim(cleanText(payload.name, 255)),
    code: trim(payload.code),
    description: trimMultiline(cleanMultiline(payload.description ?? '', 3000)),
    qualification: trim(cleanText(payload.qualification ?? '', 255)),
    duration: trim(cleanText(payload.duration ?? '', 100)),
    base_education: trim(payload.base_education || '9'),
    form: trim(payload.form || 'full-time'),
    exams: trim(cleanText(payload.exams ?? '', 500)),
    budget_places: validateIntegerRange(errors, 'budget_places', payload.budget_places, 'Бюджетные места'),
    commercial_places: validateIntegerRange(errors, 'commercial_places', payload.commercial_places, 'Коммерческие места'),
    price_per_year: validateIntegerRange(errors, 'price_per_year', payload.price_per_year, 'Стоимость обучения', 0, 10000000),
    avg_score: validateScore(errors, 'avg_score', payload.avg_score, 'Проходной балл'),
    status: trim(payload.status || 'active')
  }

  if (isBlank(data.code) || !isSpecialtyCode(data.code)) errors.code = 'Код специальности должен быть в формате 00.00.00 или 00.00.00.00'
  if (isBlank(data.name)) errors.name = 'Название специальности обязательно'
  else addLengthError(errors, 'name', data.name, 'Название специальности', { min: 3, max: 255 })
  validateSafeText(errors, 'name', payload.name, 'Название специальности')
  addLengthError(errors, 'description', data.description, 'Описание', { max: 3000 })
  validateSafeText(errors, 'description', payload.description, 'Описание')
  addLengthError(errors, 'duration', data.duration, 'Срок обучения', { max: 100 })
  validateSafeText(errors, 'duration', payload.duration, 'Срок обучения')
  addLengthError(errors, 'qualification', data.qualification, 'Квалификация', { max: 255 })
  validateSafeText(errors, 'qualification', payload.qualification, 'Квалификация')
  addLengthError(errors, 'exams', data.exams, 'Вступительные испытания', { max: 500 })
  validateSafeText(errors, 'exams', payload.exams, 'Вступительные испытания')
  if (!EDUCATION_FORMS.includes(data.form)) errors.form = 'Недопустимая форма обучения'
  if (!BASE_EDUCATION_VALUES.includes(data.base_education)) errors.base_education = 'Базовое образование должно быть 9 или 11'
  if (!SPECIALTY_STATUS_VALUES.includes(data.status)) errors.status = 'Недопустимый статус специальности'

  return { data, errors }
}

const validateAddressPayload = (payload) => {
  const errors = {}
  const data = {
    name: trim(cleanText(payload.name, 255)),
    address: trim(cleanText(payload.address, 500)),
    phone: trim(payload.phone ?? ''),
    email: cleanEmail(payload.email ?? ''),
    coordinates: trim(String(payload.coordinates || '').replace(/[^0-9.,\-\s]/g, '').slice(0, 50)),
    is_main: payload.is_main === true || payload.is_main === 'true',
    address_type: trim(payload.address_type || 'educational'),
    working_hours: trim(cleanText(payload.working_hours ?? '', 255)),
    contact_person: trim(cleanText(payload.contact_person ?? '', 255))
  }

  if (!ADDRESS_TYPE_VALUES.includes(data.address_type)) errors.address_type = 'Выберите корректный тип адреса'
  if (isBlank(data.name)) errors.name = 'Название корпуса обязательно'
  else addLengthError(errors, 'name', data.name, 'Название корпуса', { min: 2, max: 255 })
  validateSafeText(errors, 'name', payload.name, 'Название корпуса')
  if (isBlank(data.address)) errors.address = 'Адрес обязателен'
  else addLengthError(errors, 'address', data.address, 'Адрес', { min: 5, max: 500 })
  validateSafeText(errors, 'address', payload.address, 'Адрес')
  if (data.phone && !isPhone(data.phone)) errors.phone = 'Телефон должен быть в формате +7 (999) 999-99-99'
  if (data.email && (!isEmail(data.email) || data.email.length > 255)) errors.email = 'Укажите корректный email до 255 символов'
  if (data.coordinates) {
    if (!isCoordinates(data.coordinates)) {
      errors.coordinates = 'Координаты должны быть в формате: широта, долгота'
    } else {
      const [lat, lon] = data.coordinates.split(',').map((part) => Number(part.trim()))
      if (lat < -90 || lat > 90) errors.coordinates = 'Широта должна быть от -90 до 90'
      if (lon < -180 || lon > 180) errors.coordinates = 'Долгота должна быть от -180 до 180'
    }
  }
  addLengthError(errors, 'working_hours', data.working_hours, 'Режим работы', { max: 255 })
  validateSafeText(errors, 'working_hours', payload.working_hours, 'Режим работы')
  addLengthError(errors, 'contact_person', data.contact_person, 'Контактное лицо', { max: 255 })
  validateSafeText(errors, 'contact_person', payload.contact_person, 'Контактное лицо')

  return { data, errors }
}

module.exports = {
  validationResponse,
  validateCollegePayload,
  validateRepresentativePayload,
  validateSpecialtyPayload,
  validateAddressPayload
}

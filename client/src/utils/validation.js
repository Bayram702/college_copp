export const trimText = (value) => (typeof value === 'string' ? value.trim().replace(/\s+/g, ' ') : value)
export const normalizeMultilineText = (value) => (
  typeof value === 'string'
    ? value.replace(/\r\n/g, '\n').replace(/[^\S\n]+/g, ' ').trim()
    : value
)

export const normalizeTextInput = (value, max = 255) => String(value || '')
  .replace(/[\u0000-\u001f\u007f<>]/g, '')
  .replace(/\s+/g, ' ')
  .slice(0, max)

export const normalizeMultilineInput = (value, max = 3000) => String(value || '')
  .replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f<>]/g, '')
  .replace(/[^\S\n]+/g, ' ')
  .slice(0, max)

export const maskLogin = (value) => String(value || '').replace(/[^A-Za-z0-9_]/g, '').slice(0, 50)
export const normalizeEmailInput = (value) => String(value || '').trim().toLowerCase().replace(/\s/g, '').slice(0, 255)
export const normalizeUrlInput = (value) => String(value || '').trim().replace(/\s/g, '').slice(0, 255)

export const maskInteger = (value, max = 10000) => {
  const digits = String(value ?? '').replace(/\D/g, '').replace(/^0+(?=\d)/, '')
  if (!digits) return 0
  return Math.min(Number(digits), max)
}

export const maskScore = (value) => {
  const cleaned = String(value ?? '').replace(',', '.').replace(/[^\d.]/g, '')
  const [integer = '', fraction = ''] = cleaned.split('.')
  const normalized = fraction ? `${integer.slice(0, 1)}.${fraction.slice(0, 1)}` : integer.slice(0, 1)
  const number = Math.min(Number(normalized || 0), 5)
  return Number.isFinite(number) ? number : 0
}

export const maskSpecialtyCode = (value) => {
  const digits = String(value || '').replace(/\D/g, '').slice(0, 8)
  return digits.match(/.{1,2}/g)?.join('.') || ''
}

export const normalizeCoordinatesInput = (value) => String(value || '')
  .replace(/[^0-9.,\-\s]/g, '')
  .replace(/\s+/g, ' ')
  .slice(0, 50)

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
const isMailto = (value) => /^mailto:[^\s@]+@[^\s@]+\.[^\s@]+$/i.test(value)
const isLogin = (value) => /^[A-Za-z0-9_]{3,50}$/.test(value)
const isSpecialtyCode = (value) => /^\d{2}\.\d{2}\.\d{2}(\.\d{2})?$/.test(value)
const hasUnsafeText = (value) => /[<>{}\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/.test(String(value || ''))
const isCoordinates = (value) => /^-?\d{1,2}(\.\d+)?,\s*-?\d{1,3}(\.\d+)?$/.test(value)
const admissionMethods = ['offline', 'email', 'platform', 'gosuslugi', 'edu_rb']

export const normalizeUrl = (value) => {
  const cleaned = trimText(value)
  if (!cleaned) return ''
  return /^https?:\/\//i.test(cleaned) ? cleaned : `https://${cleaned}`
}

const isValidAdmissionLink = (method, value) => {
  if (!value) return true
  if (method === 'email') return isEmail(value) || isMailto(value)
  return isUrl(normalizeUrl(value))
}

const normalizeAdmissionLink = (method, value) => {
  const cleaned = normalizeUrlInput(value || '')
  if (!cleaned) return ''
  if (method === 'email') return cleaned
  return normalizeUrl(cleaned)
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

const validateSafeText = (errors, field, value, label) => {
  if (hasUnsafeText(value)) errors[field] = `${label}: нельзя использовать HTML-теги и служебные символы`
}

const validateUrlList = (errors, field, values, label) => {
  const list = Array.isArray(values) ? values : []
  if (list.length > 20) errors[field] = `${label}: максимум 20 ссылок`
  list.forEach((item, index) => {
    const url = normalizeUrl(item)
    if (url && (!isUrl(url) || url.length > 255)) errors[field] = `${label}: ссылка ${index + 1} некорректна`
  })
}

const validateTextList = (errors, field, values, label) => {
  const list = Array.isArray(values) ? values : []
  if (list.length > 50) errors[field] = `${label}: максимум 50 строк`
  list.forEach((item, index) => {
    if (hasUnsafeText(item) || String(item).length > 255) errors[field] = `${label}: строка ${index + 1} некорректна`
  })
}

const normalizeTextArray = (value) => {
  const list = Array.isArray(value) ? value : []
  return list.map((item) => trimText(normalizeTextInput(item, 255))).filter(Boolean).slice(0, 50)
}

export const validateCollege = (form) => {
  const errors = {}
  if (isBlank(form.name)) errors.name = 'Название колледжа обязательно'
  else if (trimText(form.name).length < 3 || trimText(form.name).length > 255) errors.name = 'Название: от 3 до 255 символов'
  validateSafeText(errors, 'name', form.name, 'Название')
  if (form.short_name && trimText(form.short_name).length > 50) errors.short_name = 'Краткое название: максимум 50 символов'
  if (form.description && trimText(form.description).length > 3000) errors.description = 'Описание: максимум 3000 символов'
  validateSafeText(errors, 'description', form.description, 'Описание')
  if (form.phone && !isPhone(form.phone)) errors.phone = 'Телефон: +7 (999) 999-99-99'
  if (form.email && (!isEmail(form.email) || form.email.length > 255)) errors.email = 'Укажите корректный email'
  if (form.website && (!isUrl(normalizeUrl(form.website)) || normalizeUrl(form.website).length > 255)) errors.website = 'Укажите корректный URL'
  if (form.social_vk && (!isUrl(normalizeUrl(form.social_vk)) || normalizeUrl(form.social_vk).length > 255)) errors.social_vk = 'Укажите корректный URL'
  if (form.social_max && (!isUrl(normalizeUrl(form.social_max)) || normalizeUrl(form.social_max).length > 255)) errors.social_max = 'Укажите корректный URL'
  validateUrlList(errors, 'social_other', form.social_other, 'Другие источники')
  if (!intInRange(form.budget_places)) errors.budget_places = 'Бюджетные места: целое число 0-10000'
  if (!intInRange(form.commercial_places)) errors.commercial_places = 'Коммерческие места: целое число 0-10000'
  if (!scoreInRange(form.avg_score)) errors.avg_score = 'Средний балл: 0-5, максимум 1 знак после запятой'
  if (!scoreInRange(form.min_score)) errors.min_score = 'Минимальный балл: 0-5, максимум 1 знак после запятой'
  if (!['active', 'inactive'].includes(form.status)) errors.status = 'Недопустимый статус'
  validateSafeText(errors, 'professionalitet_cluster', form.professionalitet_cluster, 'Кластер')
  validateTextList(errors, 'opportunities', form.opportunities, 'Возможности')
  validateTextList(errors, 'employers', form.employers, 'Работодатели')
  validateTextList(errors, 'workshops', form.workshops, 'Мастерские')
  validateTextList(errors, 'professions', form.professions, 'Профессии')
  validateTextList(errors, 'ovz_programs', form.ovz_programs, 'Программы ОВЗ')
  if (form.admission_method && !admissionMethods.includes(form.admission_method)) errors.admission_method = 'Выберите способ подачи документов'
  if (form.admission_method === 'offline' && isBlank(form.admission_instructions)) errors.admission_instructions = 'Для очной подачи нужна инструкция'
  if (['email', 'platform', 'gosuslugi', 'edu_rb'].includes(form.admission_method) && isBlank(form.admission_link)) errors.admission_link = 'Для выбранного способа нужна ссылка'
  if (form.admission_link && (!isValidAdmissionLink(form.admission_method, form.admission_link) || normalizeAdmissionLink(form.admission_method, form.admission_link).length > 255)) errors.admission_link = 'Укажите корректную ссылку'
  if (form.admission_instructions && trimText(form.admission_instructions).length > 1000) errors.admission_instructions = 'Инструкция: максимум 1000 символов'
  validateSafeText(errors, 'admission_instructions', form.admission_instructions, 'Инструкция по подаче документов')
  return errors
}

export const normalizeCollege = (form) => ({
  ...form,
  name: trimText(normalizeTextInput(form.name, 255)),
  short_name: trimText(form.short_name || ''),
  description: normalizeMultilineText(normalizeMultilineInput(form.description || '', 3000)),
  phone: trimText(form.phone || ''),
  email: normalizeEmailInput(form.email || ''),
  website: normalizeUrl(normalizeUrlInput(form.website)),
  social_vk: normalizeUrl(normalizeUrlInput(form.social_vk)),
  social_max: normalizeUrl(normalizeUrlInput(form.social_max)),
  social_other: Array.isArray(form.social_other) ? form.social_other.map((url) => normalizeUrl(normalizeUrlInput(url))).filter(Boolean).slice(0, 20) : [],
  avg_score: maskScore(form.avg_score),
  min_score: maskScore(form.min_score),
  professionalitet_cluster: trimText(normalizeTextInput(form.professionalitet_cluster || '', 255)),
  opportunities: normalizeTextArray(form.opportunities),
  employers: normalizeTextArray(form.employers),
  workshops: normalizeTextArray(form.workshops),
  professions: normalizeTextArray(form.professions),
  ovz_programs: normalizeTextArray(form.ovz_programs),
  admission_method: form.admission_method || '',
  admission_link: normalizeAdmissionLink(form.admission_method, form.admission_link),
  admission_instructions: normalizeMultilineText(normalizeMultilineInput(form.admission_instructions || '', 1000))
})

export const validateRepresentative = (form, { editing = false } = {}) => {
  const errors = {}
  const role = form.role || 'college_rep'
  if (isBlank(form.name) || trimText(form.name).length < 2 || trimText(form.name).length > 255) errors.name = 'ФИО: от 2 до 255 символов'
  validateSafeText(errors, 'name', form.name, 'ФИО')
  if (isBlank(form.login) || !isLogin(trimText(form.login))) errors.login = 'Логин: латиница, цифры и _, 3-50 символов'
  if (isBlank(form.email) || !isEmail(trimText(form.email)) || trimText(form.email).length > 255) errors.email = 'Укажите корректный email'
  if (form.phone && !isPhone(form.phone)) errors.phone = 'Телефон: +7 (999) 999-99-99'
  if (!editing && (!form.password || form.password.length < 8 || form.password.length > 100)) errors.password = 'Пароль: от 8 до 100 символов'
  if (editing && form.password && (form.password.length < 8 || form.password.length > 100)) errors.password = 'Новый пароль: от 8 до 100 символов'
  if (!['active', 'inactive'].includes(form.status)) errors.status = 'Недопустимый статус'
  if (role === 'college_rep' && form.status === 'active' && !form.college_id) errors.college_id = 'Для активного представителя выберите колледж'
  return errors
}

export const normalizeRepresentative = (form) => {
  const role = form.role || 'college_rep'
  const collegeId = role === 'college_rep' ? (form.college_id || null) : null
  return {
    ...form,
    name: trimText(normalizeTextInput(form.name, 255)),
    login: maskLogin(form.login),
    email: normalizeEmailInput(form.email),
    phone: trimText(form.phone || ''),
    role,
    college_id: collegeId,
    status: form.status
  }
}

export const validateSpecialty = (form) => {
  const errors = {}
  if ((!form.specialty_id || Number(form.specialty_id) <= 0) && (isBlank(form.code) || !isSpecialtyCode(trimText(form.code)))) errors.code = 'Код: 00.00.00 или 00.00.00.00'
  if (!form.sector_id || Number(form.sector_id) <= 0) errors.sector_id = 'Выберите отрасль'
  if (!form.specialty_id || Number(form.specialty_id) <= 0) errors.specialty_id = 'Выберите специальность'
  if ((!form.specialty_id || Number(form.specialty_id) <= 0) && (isBlank(form.name) || trimText(form.name).length < 3 || trimText(form.name).length > 255)) errors.name = 'Название: от 3 до 255 символов'
  validateSafeText(errors, 'name', form.name, 'Название')
  if (form.description && trimText(form.description).length > 3000) errors.description = 'Описание: максимум 3000 символов'
  validateSafeText(errors, 'description', form.description, 'Описание')
  if (form.duration && trimText(form.duration).length > 100) errors.duration = 'Срок обучения: максимум 100 символов'
  validateSafeText(errors, 'duration', form.duration, 'Срок обучения')
  if (form.qualification && trimText(form.qualification).length > 255) errors.qualification = 'Квалификация: максимум 255 символов'
  validateSafeText(errors, 'qualification', form.qualification, 'Квалификация')
  if (form.exams && trimText(form.exams).length > 500) errors.exams = 'Вступительные испытания: максимум 500 символов'
  validateSafeText(errors, 'exams', form.exams, 'Вступительные испытания')
  if (isBlank(form.teaching_address) || trimText(form.teaching_address).length < 5 || trimText(form.teaching_address).length > 500) errors.teaching_address = 'Адрес преподавания: от 5 до 500 символов'
  validateSafeText(errors, 'teaching_address', form.teaching_address, 'Адрес преподавания')
  if (!['full-time', 'part-time', 'distance'].includes(form.form)) errors.form = 'Недопустимая форма обучения'
  if (!['9', '11'].includes(String(form.base_education))) errors.base_education = 'Базовое образование: 9 или 11'
  if (!intInRange(form.budget_places)) errors.budget_places = 'Бюджетные места: целое число 0-10000'
  if (!intInRange(form.commercial_places)) errors.commercial_places = 'Коммерческие места: целое число 0-10000'
  if (!intInRange(form.price_per_year, 0, 10000000)) errors.price_per_year = 'Стоимость: целое число от 0'
  if (!scoreInRange(form.avg_score)) errors.avg_score = 'Проходной балл: 0-5, максимум 1 знак после запятой'
  if (!['active', 'inactive', 'draft'].includes(form.status)) errors.status = 'Недопустимый статус'
  if (form.admission_method && !admissionMethods.includes(form.admission_method)) errors.admission_method = 'Выберите способ подачи документов'
  if (form.admission_method === 'offline' && isBlank(form.admission_instructions)) errors.admission_instructions = 'Для очной подачи нужна инструкция'
  if (['email', 'platform', 'gosuslugi', 'edu_rb'].includes(form.admission_method) && isBlank(form.admission_link)) errors.admission_link = 'Для выбранного способа нужна ссылка'
  if (form.admission_link && (!isValidAdmissionLink(form.admission_method, form.admission_link) || normalizeAdmissionLink(form.admission_method, form.admission_link).length > 255)) errors.admission_link = 'Укажите корректную ссылку'
  if (form.admission_instructions && trimText(form.admission_instructions).length > 1000) errors.admission_instructions = 'Инструкция: максимум 1000 символов'
  validateSafeText(errors, 'admission_instructions', form.admission_instructions, 'Инструкция по подаче документов')
  return errors
}

export const normalizeSpecialty = (form) => ({
  ...form,
  sector_id: form.sector_id || '',
  specialty_id: form.specialty_id || '',
  code: maskSpecialtyCode(form.code),
  name: trimText(normalizeTextInput(form.name, 255)),
  description: normalizeMultilineText(normalizeMultilineInput(form.description || '', 3000)),
  qualification: trimText(normalizeTextInput(form.qualification || '', 255)),
  duration: trimText(normalizeTextInput(form.duration || '', 100)),
  exams: trimText(normalizeTextInput(form.exams || '', 500)),
  teaching_address: trimText(normalizeTextInput(form.teaching_address || '', 500)),
  admission_method: form.admission_method || '',
  admission_link: normalizeAdmissionLink(form.admission_method, form.admission_link),
  admission_instructions: normalizeMultilineText(normalizeMultilineInput(form.admission_instructions || '', 1000))
})

export const validateAddress = (form) => {
  const errors = {}
  if (!['legal', 'actual', 'educational', 'branch', 'other'].includes(form.address_type)) errors.address_type = 'Выберите тип адреса'
  if (isBlank(form.name) || trimText(form.name).length < 2 || trimText(form.name).length > 255) errors.name = 'Название корпуса: от 2 до 255 символов'
  validateSafeText(errors, 'name', form.name, 'Название корпуса')
  if (isBlank(form.address) || trimText(form.address).length < 5 || trimText(form.address).length > 500) errors.address = 'Адрес: от 5 до 500 символов'
  validateSafeText(errors, 'address', form.address, 'Адрес')
  if (form.phone && !isPhone(form.phone)) errors.phone = 'Телефон: +7 (999) 999-99-99'
  if (form.email && (!isEmail(trimText(form.email)) || trimText(form.email).length > 255)) errors.email = 'Укажите корректный email'
  if (form.coordinates) {
    const coordinates = trimText(form.coordinates)
    if (!isCoordinates(coordinates)) errors.coordinates = 'Координаты: широта, долгота'
    const [lat, lon] = coordinates.split(',').map((part) => Number(part.trim()))
    if (Number.isFinite(lat) && (lat < -90 || lat > 90)) errors.coordinates = 'Широта должна быть от -90 до 90'
    if (Number.isFinite(lon) && (lon < -180 || lon > 180)) errors.coordinates = 'Долгота должна быть от -180 до 180'
  }
  if (form.working_hours && trimText(form.working_hours).length > 255) errors.working_hours = 'Режим работы: максимум 255 символов'
  validateSafeText(errors, 'working_hours', form.working_hours, 'Режим работы')
  if (form.contact_person && trimText(form.contact_person).length > 255) errors.contact_person = 'Контактное лицо: максимум 255 символов'
  validateSafeText(errors, 'contact_person', form.contact_person, 'Контактное лицо')
  return errors
}

export const normalizeAddress = (form) => ({
  ...form,
  name: trimText(normalizeTextInput(form.name, 255)),
  address: trimText(normalizeTextInput(form.address, 500)),
  phone: trimText(form.phone || ''),
  email: normalizeEmailInput(form.email || ''),
  coordinates: trimText(normalizeCoordinatesInput(form.coordinates || '')),
  working_hours: trimText(normalizeTextInput(form.working_hours || '', 255)),
  contact_person: trimText(normalizeTextInput(form.contact_person || '', 255))
})

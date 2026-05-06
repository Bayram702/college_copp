<template>
  <div class="admin-panel">
    <div class="breadcrumbs">
      <div class="container">
        <router-link to="/">Главная</router-link> >
        <span>Панель администратора</span>
      </div>
    </div>

    <!-- Вкладки -->
    <div class="container">
      <div class="tabs">
        <button
          class="tab-btn"
          :class="{ active: activeTab === 'users' }"
          @click="activeTab = 'users'"
        >
          <i class="fas fa-users"></i> Пользователи
        </button>
        <button
          class="tab-btn"
          :class="{ active: activeTab === 'colleges' }"
          @click="activeTab = 'colleges'"
        >
          <i class="fas fa-graduation-cap"></i> Колледжи
        </button>
        <button
          class="tab-btn"
          :class="{ active: activeTab === 'settings' }"
          @click="activeTab = 'settings'"
        >
          <i class="fas fa-cog"></i> Настройки
        </button>
      </div>
    </div>

    <!-- Основной контент -->
    <div class="container">
      <!-- Уведомления -->
      <div v-if="alertMessage" :class="['alert', `alert-${alertType}`]">
        <i :class="alertType === 'success' ? 'fas fa-check-circle' : 'fas fa-info-circle'"></i>
        <div>{{ alertMessage }}</div>
      </div>

      <!-- Вкладка: Пользователи -->
      <div v-if="activeTab === 'users'" class="tab-content active">
        <div class="specialities-header">
          <div class="search-box">
            <i class="fas fa-search"></i>
            <input v-model="userSearch" type="text" placeholder="Поиск пользователей..." @input="debouncedSearch">
          </div>
          <button class="btn-add" @click="openAddRepModal">
            <i class="fas fa-user-plus"></i> Добавить представителя колледжа
          </button>
        </div>

        <!-- Фильтры -->
        <div class="filters-bar">
          <select v-model="userFilters.role" @change="applyUserFilters" class="filter-select">
            <option value="all">Все роли</option>
            <option value="admin">Администраторы</option>
            <option value="college_rep">Представители колледжей</option>
          </select>
          <select v-model="userFilters.status" @change="applyUserFilters" class="filter-select">
            <option value="all">Все статусы</option>
            <option value="active">Активные</option>
            <option value="inactive">Неактивные</option>
          </select>
        </div>

        <!-- Таблица пользователей -->
        <div v-if="usersLoading" class="loading-state">
          <i class="fas fa-spinner fa-spin"></i> Загрузка...
        </div>
        <div v-else-if="usersError" class="error-state">
          <i class="fas fa-exclamation-triangle"></i> {{ usersError }}
          <button @click="fetchUsers" class="btn-retry">Повторить</button>
        </div>
        <div v-else class="table-container users-table-container">
          <div class="table-scroll">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Номер</th>
                  <th>Пользователь</th>
                  <th>Логин</th>
                  <th>Email</th>
                  <th>Роль</th>
                  <th>Статус</th>
                  <th>Дата регистрации</th>
                  <th>Действия</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="user in users" :key="user.id">
                  <td>{{ user.id }}</td>
                  <td>
                    <div class="user-info">
                      <div class="user-avatar">{{ user.name.charAt(0) }}</div>
                      <span>{{ user.name }}</span>
                    </div>
                  </td>
                  <td>{{ user.login }}</td>
                  <td>{{ user.email }}</td>
                  <td>
                    <span class="role-badge" :class="user.role.name">{{ getRoleName(user.role.name) }}</span>
                  </td>
                  <td>
                    <span class="status-badge" :class="getStatusClass(user.status)">{{ getStatusName(user.status) }}</span>
                  </td>
                  <td>{{ formatDate(user.createdAt) }}</td>
                  <td>
                    <div class="action-buttons">
                      <button class="btn-icon btn-edit" @click="editUser(user)" title="Редактировать">
                        <i class="fas fa-edit"></i>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Пагинация -->
          <div v-if="userPagination.totalPages > 1" class="pagination">
            <button class="page-btn" :disabled="userPagination.page === 1" @click="changeUserPage(userPagination.page - 1)">
              <i class="fas fa-chevron-left"></i>
            </button>
            <button v-for="page in visibleUserPages" :key="page" class="page-btn" :class="{ active: userPagination.page === page, dots: page === '...' }" :disabled="page === '...'" @click="changeUserPage(page)">
              {{ page }}
            </button>
            <button class="page-btn" :disabled="userPagination.page === userPagination.totalPages" @click="changeUserPage(userPagination.page + 1)">
              <i class="fas fa-chevron-right"></i>
            </button>
          </div>
        </div>
      </div>

      <!-- Вкладка: Колледжи -->
      <div v-if="activeTab === 'colleges'" class="tab-content active">
        <div class="specialities-header">
          <div class="search-box">
            <i class="fas fa-search"></i>
            <input v-model="collegeSearch" type="text" placeholder="Поиск колледжей..." @input="filterColleges">
          </div>
        </div>
        <div class="filters-bar">
          <select v-model="collegeFilter" @change="filterColleges" class="filter-select">
            <option value="all">Все колледжи</option>
            <option value="active">Активные</option>
            <option value="with_rep">С представителем</option>
            <option value="without_rep">Без представителя</option>
          </select>
        </div>

        <div v-if="collegesLoading" class="loading-state">
          <i class="fas fa-spinner fa-spin"></i> Загрузка...
        </div>
        <div v-else-if="collegesError" class="error-state">
          <i class="fas fa-exclamation-triangle"></i> {{ collegesError }}
          <button @click="fetchColleges" class="btn-retry">Повторить</button>
        </div>
        <div v-else class="table-container">
          <table class="data-table">
            <thead>
              <tr>
                <th>Номер</th>
                <th>Колледж</th>
                <th>Город</th>
                <th>Статус</th>
                <th>Профессионалитет</th>
                <th>Представитель</th>
                <th>Обновлен</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="college in filteredCollegesList" :key="college.id">
                <td>{{ college.id }}</td>
                <td>
                  <div class="college-info">
                    <strong>{{ college.name }}</strong>
                    <span class="short-name">{{ college.short_name }}</span>
                  </div>
                </td>
                <td>{{ college.city }}</td>
                <td>
                  <span class="status-badge" :class="getStatusClass(college.status)">{{ getStatusName(college.status) }}</span>
                </td>
                <td>
                  <span v-if="college.is_professionalitet" class="prof-badge">
                    <i class="fas fa-check-circle"></i> {{ college.professionalitet_cluster || 'Да' }}
                  </span>
                  <span v-else class="text-muted">Нет</span>
                </td>
                <td>
                  <div v-if="college.representatives.length > 0" class="rep-list">
                    <div v-for="rep in college.representatives" :key="rep.id" class="rep-item">
                      <i class="fas fa-user"></i> {{ rep.name }}
                      <span class="rep-status" :class="rep.status">{{ getStatusName(rep.status) }}</span>
                    </div>
                  </div>
                  <span v-else class="text-muted"><i class="fas fa-user-slash"></i> Нет</span>
                </td>
                <td>{{ formatDate(college.updated_at) }}</td>
              </tr>
            </tbody>
          </table>
          <div v-if="filteredCollegesList.length === 0" class="empty-state">
            <i class="fas fa-graduation-cap"></i>
            <p>Колледжи не найдены</p>
          </div>
        </div>
      </div>

      <!-- Вкладка: Настройки -->
      <div v-if="activeTab === 'settings'" class="tab-content active">
        <div class="alert alert-info">
          <i class="fas fa-info-circle"></i>
          <div><strong>В разработке:</strong> Здесь будут настройки главной страницы портала.</div>
        </div>
      </div>
    </div>

    <!-- Модальное окно пользователя -->
    <div class="modal-overlay" :class="{ active: showUserModal }" @click.self="closeUserModal" v-show="showUserModal">
      <div class="modal">
        <button class="close-modal" @click="closeUserModal">&times;</button>
        <h2>{{ editingUser ? 'Редактировать пользователя' : 'Добавить пользователя' }}</h2>
        <form @submit.prevent="saveUser" class="modal-form">
          <div class="form-row">
            <div class="form-group">
              <label>Имя <span class="required">*</span></label>
              <input v-model="userForm.name" type="text" class="form-control" :class="{ invalid: userErrors.name }" maxlength="255" @input="userForm.name = normalizeTextInput(userForm.name, 255)" required>
              <small v-if="userErrors.name" class="field-error">{{ userErrors.name }}</small>
            </div>
            <div class="form-group">
              <label>Логин <span class="required">*</span></label>
              <input v-model="userForm.login" type="text" class="form-control" :class="{ invalid: userErrors.login }" maxlength="50" @input="userForm.login = maskLogin(userForm.login)" required>
              <small v-if="userErrors.login" class="field-error">{{ userErrors.login }}</small>
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Email <span class="required">*</span></label>
              <input v-model="userForm.email" type="email" class="form-control" :class="{ invalid: userErrors.email }" maxlength="255" @input="userForm.email = normalizeEmailInput(userForm.email)" required>
              <small v-if="userErrors.email" class="field-error">{{ userErrors.email }}</small>
              <small v-if="!editingUser" class="form-hint">📧 На этот email будут отправлены логин и пароль для входа</small>
            </div>
            <div class="form-group">
              <label v-if="!editingUser">Пароль <span class="required">*</span></label>
              <label v-else>Новый пароль</label>
              <input :type="showPassword ? 'text' : 'password'" v-model="userForm.password" class="form-control" :class="{ invalid: userErrors.password }" maxlength="100" :required="!editingUser">
              <small v-if="userErrors.password" class="field-error">{{ userErrors.password }}</small>
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Статус</label>
              <select v-model="userForm.status" class="form-control" :class="{ invalid: userErrors.status }">
                <option value="active">Активный</option>
                <option value="inactive">Неактивный</option>
              </select>
            </div>
          </div>
          <div class="form-group">
            <label>Телефон</label>
            <input v-model="userForm.phone" type="tel" class="form-control" :class="{ invalid: userErrors.phone }" placeholder="+7 (999) 999-99-99" @input="userForm.phone = maskRussianPhone(userForm.phone)">
            <small v-if="userErrors.phone" class="field-error">{{ userErrors.phone }}</small>
          </div>
          <div class="form-group">
            <label>Колледж</label>
            <select v-model="userForm.college_id" class="form-control" :class="{ invalid: userErrors.college_id }">
              <option value="">Выберите колледж</option>
              <option v-for="c in availableColleges" :key="c.id" :value="c.id">{{ c.name }}</option>
            </select>
            <small v-if="userErrors.college_id" class="field-error">{{ userErrors.college_id }}</small>
          </div>
          <div class="form-actions">
            <button type="submit" class="btn btn-primary" :disabled="saving">
              <i :class="saving ? 'fas fa-spinner fa-spin' : 'fas fa-save'"></i> {{ saving ? 'Сохранение...' : 'Сохранить' }}
            </button>
            <button type="button" class="btn btn-secondary" @click="closeUserModal">Отмена</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'
import {
  firstError,
  maskLogin,
  maskRussianPhone,
  normalizeEmailInput,
  normalizeRepresentative,
  normalizeTextInput,
  validateRepresentative
} from '../utils/validation'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api'
const router = useRouter()

const activeTab = ref('users')
const alertMessage = ref('')
const alertType = ref('info')
const saving = ref(false)

// Пользователи
const users = ref([])
const usersLoading = ref(false)
const usersError = ref(null)
const userSearch = ref('')
const userFilters = ref({ role: 'all', status: 'all' })
const userPagination = ref({ total: 0, page: 1, limit: 10, totalPages: 0 })

// Колледжи
const colleges = ref([])
const collegesLoading = ref(false)
const collegesError = ref(null)
const collegeSearch = ref('')
const collegeFilter = ref('all')
const filteredCollegesList = ref([])

// Модальное окно
const showUserModal = ref(false)
const editingUser = ref(null)
const showPassword = ref(false)
const userForm = ref({ name: '', login: '', email: '', phone: '', password: '', role: 'college_rep', status: '', college_id: '' })
const userErrors = ref({})
const availableColleges = ref([])

// Загрузка списка колледжей для модалки
const loadCollegesForSelect = async () => {
  try {
    const token = localStorage.getItem('authToken')
    const res = await axios.get(`${API_URL}/colleges/admin/list`, { headers: { 'Authorization': `Bearer ${token}` } })
    if (res.data.success) {
      const currentCollegeId = editingUser.value
        ? String(userForm.value.college_id || editingUser.value.college?.id || editingUser.value.college_id || '')
        : ''
      availableColleges.value = res.data.data.filter((college) => {
        const representatives = college.representatives || []
        return representatives.length === 0 || String(college.id) === currentCollegeId
      })
    }
  } catch (e) { console.warn('Колледжи не загружены:', e) }
}

let searchTimeout = null

onMounted(() => {
  const token = localStorage.getItem('authToken')
  if (token) axios.defaults.headers.common['Authorization'] = `Bearer ${token}`
  fetchUsers()
})

watch(activeTab, (tab) => {
  if (tab === 'colleges' && colleges.value.length === 0) fetchColleges()
})

// Пользователи
const fetchUsers = async () => {
  usersLoading.value = true
  usersError.value = null
  try {
    const token = localStorage.getItem('authToken')
    const params = new URLSearchParams({ page: userPagination.value.page, limit: userPagination.value.limit })
    if (userFilters.value.role !== 'all') params.append('role', userFilters.value.role)
    if (userFilters.value.status !== 'all') params.append('status', userFilters.value.status)
    if (userSearch.value.trim()) params.append('search', userSearch.value.trim())

    const response = await axios.get(`${API_URL}/users?${params.toString()}`, { headers: { 'Authorization': `Bearer ${token}` } })
    if (response.data.success) {
      users.value = response.data.data
      userPagination.value = response.data.pagination
    }
  } catch (err) {
    usersError.value = err.response?.status === 401 ? 'Сессия истекла' : err.message
    if (err.response?.status === 401) { localStorage.removeItem('authToken'); localStorage.removeItem('user'); router.push('/login') }
  } finally { usersLoading.value = false }
}

const debouncedSearch = () => {
  clearTimeout(searchTimeout)
  searchTimeout = setTimeout(() => { userPagination.value.page = 1; fetchUsers() }, 300)
}

const applyUserFilters = () => {
  userPagination.value.page = 1
  fetchUsers()
}

const changeUserPage = (page) => {
  if (typeof page === 'number' && page >= 1 && page <= userPagination.value.totalPages) { userPagination.value.page = page; fetchUsers() }
}

const visibleUserPages = computed(() => {
  const pages = []; const total = userPagination.value.totalPages; const current = userPagination.value.page
  if (total <= 7) {
    for (let i = 1; i <= total; i++) pages.push(i)
  } else {
    pages.push(1)
    if (current > 4) pages.push('...')
    const start = Math.max(2, current - 1)
    const end = Math.min(total - 1, current + 1)
    for (let i = start; i <= end; i++) pages.push(i)
    if (current < total - 3) pages.push('...')
    pages.push(total)
  }
  return pages
})

const getRoleName = (role) => ({ admin: 'Администратор', college_rep: 'Представитель' }[role] || role)
const normalizeUserStatus = (status) => status === 'blocked' ? 'inactive' : status
const getStatusName = (status) => ({ active: 'Активный', inactive: 'Неактивный' }[normalizeUserStatus(status)] || status)
const getStatusClass = (status) => ({ active: 'status-active', inactive: 'status-inactive' }[normalizeUserStatus(status)] || '')
const formatDate = (d) => d ? new Date(d).toLocaleDateString('ru-RU') : '—'

const openAddRepModal = () => {
  console.log('👤 openAddRepModal вызван')
  editingUser.value = null
  userErrors.value = {}
  userForm.value = { name: '', login: '', email: '', phone: '', password: '', role: 'college_rep', status: 'active', college_id: '' }
  showPassword.value = false
  showUserModal.value = true
  console.log('👤 showUserModal =', showUserModal.value)
  loadCollegesForSelect()
}
const closeUserModal = () => { showUserModal.value = false; userErrors.value = {} }
const editUser = (user) => {
  if (user.role?.name !== 'college_rep') {
    alertMessage.value = 'Редактировать здесь можно только представителей колледжей'
    alertType.value = 'error'
    return
  }
  editingUser.value = user
  userErrors.value = {}
  userForm.value = {
    name: user.name || '',
    login: user.login || '',
    email: user.email || '',
    phone: user.phone || '',
    password: '',
    role: 'college_rep',
    status: user.status || 'active',
    college_id: user.college?.id || user.college_id || ''
  }
  showUserModal.value = true
  loadCollegesForSelect()
}

const saveUser = async () => {
  userForm.value.role = 'college_rep'
  userErrors.value = validateRepresentative(userForm.value, { editing: !!editingUser.value })
  if (Object.keys(userErrors.value).length) {
    alertMessage.value = firstError(userErrors.value)
    alertType.value = 'error'
    return
  }
  if (!userForm.value.email?.trim()) {
    alertMessage.value = 'Email обязателен — на него будут отправлены логин и пароль'; alertType.value = 'error'; return
  }
  saving.value = true
  try {
    const token = localStorage.getItem('authToken')
    const body = normalizeRepresentative(userForm.value)
    let response
    if (editingUser.value) {
      response = await axios.put(`${API_URL}/users/${editingUser.value.id}`, body, { headers: { Authorization: `Bearer ${token}` } })
    } else {
      response = await axios.post(`${API_URL}/users`, body, { headers: { Authorization: `Bearer ${token}` } })
    }
    closeUserModal()
    fetchUsers()

    // Показываем результат отправки email
    if (response.data.email_sent) {
      alertMessage.value = `Пользователь создан. Email с логином и паролем отправлен на ${userForm.value.email}`
      alertType.value = 'success'
    } else if (response.data.credentials) {
      alertMessage.value = `Пользователь создан. SMTP не настроен. Логин: ${response.data.credentials.login}, Пароль: ${response.data.credentials.password}`
      alertType.value = 'info'
    } else {
      alertMessage.value = 'Пользователь сохранён'
      alertType.value = 'success'
    }
  } catch (e) {
    userErrors.value = e.response?.data?.errors || {}
    alertMessage.value = 'Ошибка: ' + (e.response?.data?.error || e.message)
    alertType.value = 'error'
  }
  finally { saving.value = false }
}

// Колледжи
const fetchColleges = async () => {
  collegesLoading.value = true; collegesError.value = null
  try {
    const token = localStorage.getItem('authToken')
    const response = await axios.get(`${API_URL}/colleges/admin/list`, { headers: { 'Authorization': `Bearer ${token}` } })
    if (response.data.success) { colleges.value = response.data.data; filteredCollegesList.value = colleges.value }
  } catch (err) {
    collegesError.value = err.response?.status === 401 ? 'Сессия истекла' : err.message
    if (err.response?.status === 401) { localStorage.removeItem('authToken'); localStorage.removeItem('user'); router.push('/login') }
  } finally { collegesLoading.value = false }
}

const filterColleges = () => {
  let filtered = [...colleges.value]
  if (collegeSearch.value.trim()) {
    const s = collegeSearch.value.trim().toLowerCase()
    filtered = filtered.filter(c => c.name.toLowerCase().includes(s) || c.short_name?.toLowerCase().includes(s) || c.city.toLowerCase().includes(s))
  }
  if (collegeFilter.value === 'active') filtered = filtered.filter(c => c.status === 'active')
  else if (collegeFilter.value === 'with_rep') filtered = filtered.filter(c => c.representatives.length > 0)
  else if (collegeFilter.value === 'without_rep') filtered = filtered.filter(c => c.representatives.length === 0)
  filteredCollegesList.value = filtered
}

const logout = () => {
  if (confirm('Выйти из системы?')) {
    localStorage.removeItem('authToken'); localStorage.removeItem('user')
    delete axios.defaults.headers.common['Authorization']
    router.push('/login')
  }
}
</script>

<style scoped>
.admin-panel { min-height: 100vh; background: #f5f7fa; }

/* Хедер панели */
.panel-header { background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); color: white; padding: 20px 0; margin-bottom: 0; }
.panel-header .header-content { display: flex; justify-content: space-between; align-items: center; }
.panel-header .logo { display: flex; align-items: center; gap: 15px; }
.panel-header .logo-icon { width: 50px; height: 50px; background: rgba(255,255,255,0.2); border-radius: 10px; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 1.3rem; }
.panel-header h1 { margin: 0; font-size: 1.4rem; }
.panel-header p { margin: 3px 0 0; opacity: 0.8; font-size: 0.9rem; }
.panel-header .logout-btn { background: rgba(255,255,255,0.2); color: white; border: none; padding: 10px 20px; border-radius: 8px; cursor: pointer; font-weight: 600; display: flex; align-items: center; gap: 8px; transition: all 0.3s; }
.panel-header .logout-btn:hover { background: rgba(255,255,255,0.3); }

/* Вкладки */
.tabs { display: flex; gap: 8px; padding: 20px 0 0; }
.tab-btn { padding: 12px 24px; background: white; border: none; border-radius: 10px 10px 0 0; cursor: pointer; font-weight: 500; transition: all 0.3s; display: flex; align-items: center; gap: 8px; color: #64748b; border-bottom: 3px solid transparent; }
.tab-btn:hover { background: #e2e8f0; }
.tab-btn.active { background: white; color: #1e3c72; border-bottom-color: #1e3c72; box-shadow: 0 -2px 10px rgba(0,0,0,0.05); }

/* Контент вкладок */
.tab-content { display: none; padding: 30px 0; }
.tab-content.active { display: block; }

/* Уведомления */
.alert { padding: 14px 18px; border-radius: 10px; margin-bottom: 20px; display: flex; align-items: center; gap: 10px; }
.alert-success { background: #d1fae5; color: #059669; }
.alert-error { background: #fee2e2; color: #dc2626; }
.alert-info { background: #dbeafe; color: #2563eb; }

/* Поиск и фильтры */
.specialities-header { display: flex; gap: 15px; margin-bottom: 15px; align-items: center; }
.search-box { flex: 1; max-width: 400px; position: relative; }
.search-box i { position: absolute; left: 15px; top: 50%; transform: translateY(-50%); color: #94a3b8; }
.search-box input { width: 100%; padding: 12px 15px 12px 45px; border: 1px solid #e1e8ed; border-radius: 8px; }
.btn-add { padding: 12px 24px; background: linear-gradient(135deg, #667eea, #764ba2); color: white; border: none; border-radius: 8px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 8px; transition: all 0.3s; }
.btn-add:hover { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(102,126,234,0.4); }
.filters-bar { display: flex; gap: 15px; margin-bottom: 20px; }
.filter-select { padding: 10px 15px; border: 1px solid #e1e8ed; border-radius: 8px; background: white; }

/* Таблица */
.table-container { background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.05); }
.table-scroll { width: 100%; overflow-x: auto; }
.users-table-container .table-scroll { max-height: 620px; overflow-y: auto; }
.data-table { width: 100%; border-collapse: collapse; }
.users-table-container .data-table { min-width: 920px; }
.users-table-container .data-table thead { position: sticky; top: 0; z-index: 1; }
.data-table th { background: #f8fafc; padding: 15px; text-align: left; font-weight: 600; color: #475569; border-bottom: 2px solid #e1e8ed; }
.data-table td { padding: 15px; border-bottom: 1px solid #f1f5f9; }
.data-table tbody tr:hover { background: #f8fafc; }

.user-info { display: flex; align-items: center; gap: 12px; }
.user-avatar { width: 40px; height: 40px; background: linear-gradient(135deg, #667eea, #764ba2); border-radius: 50%; display: flex; align-items: center; justify-content: center; color: white; font-weight: 600; }

.role-badge, .status-badge { padding: 5px 12px; border-radius: 20px; font-size: 0.85rem; font-weight: 500; display: inline-block; }
.role-badge.college_rep { background: #d1fae5; color: #059669; }
.role-badge.admin { background: #fee2e2; color: #dc2626; }
.status-badge.status-active { background: #d1fae5; color: #059669; }
.status-badge.status-inactive { background: #fef3c7; color: #d97706; }

.prof-badge { background: #d1fae5; color: #059669; padding: 4px 10px; border-radius: 12px; font-size: 0.8rem; font-weight: 500; display: inline-flex; align-items: center; gap: 5px; }
.rep-list { display: flex; flex-direction: column; gap: 4px; }
.rep-item { display: flex; align-items: center; gap: 6px; font-size: 0.85rem; }
.rep-status { font-size: 0.7rem; padding: 2px 6px; border-radius: 8px; }
.rep-status.active { background: #d1fae5; color: #059669; }
.rep-status.inactive { background: #fef3c7; color: #d97706; }
.text-muted { color: #94a3b8; font-size: 0.85rem; }

.college-info { display: flex; flex-direction: column; gap: 4px; }
.college-info strong { color: #1e293b; }
.short-name { color: #64748b; font-size: 0.8rem; background: #f1f5f9; padding: 2px 8px; border-radius: 4px; display: inline-block; width: fit-content; }

.action-buttons { display: flex; gap: 8px; }
.btn-icon { width: 36px; height: 36px; border: none; border-radius: 6px; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.3s; }
.btn-edit { background: #dbeafe; color: #2563eb; }
.btn-edit:hover { background: #2563eb; color: white; }
.btn-delete { background: #fef3c7; color: #d97706; }
.btn-delete:hover { background: #d97706; color: white; }

.pagination { display: flex; justify-content: center; gap: 8px; padding: 20px; border-top: 1px solid #f1f5f9; }
.page-btn { width: 40px; height: 40px; border: 1px solid #e1e8ed; background: white; border-radius: 8px; cursor: pointer; }
.page-btn:hover:not(:disabled) { background: #f1f5f9; }
.page-btn.active { background: linear-gradient(135deg, #667eea, #764ba2); color: white; border-color: transparent; }
.page-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.page-btn.dots { border-color: transparent; background: transparent; }

.loading-state, .error-state { text-align: center; padding: 60px 20px; color: #64748b; }
.loading-state i { font-size: 2rem; color: #667eea; }
.error-state { color: #dc2626; }
.btn-retry { margin-top: 15px; padding: 10px 20px; background: #667eea; color: white; border: none; border-radius: 8px; cursor: pointer; }
.empty-state { text-align: center; padding: 60px 20px; color: #64748b; }
.empty-state i { font-size: 3rem; color: #cbd5e1; margin-bottom: 15px; }

/* Модальное окно */
.modal-overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 2000; }
.modal { background: white; border-radius: 16px; width: 90%; max-width: 600px; padding: 30px; position: relative; max-height: 90vh; overflow-y: auto; }
.close-modal { position: absolute; top: 20px; right: 20px; background: none; border: none; font-size: 1.5rem; cursor: pointer; color: #64748b; }
.modal h2 { margin: 0 0 25px 0; color: #1e293b; }
.modal-form { display: flex; flex-direction: column; gap: 20px; }
.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
.form-group label { display: block; margin-bottom: 8px; font-weight: 500; color: #475569; }
.form-control { width: 100%; padding: 12px 15px; border: 1px solid #e1e8ed; border-radius: 8px; font-size: 1rem; }
.form-control.invalid { border-color: #dc2626; box-shadow: 0 0 0 3px rgba(220, 38, 38, 0.08); }
.field-error { color: #dc2626; font-size: 0.8rem; margin-top: 4px; display: block; }
.form-actions { display: flex; gap: 15px; margin-top: 20px; }
.btn { padding: 12px 24px; border: none; border-radius: 8px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 8px; transition: all 0.3s; }
.btn-primary { background: linear-gradient(135deg, #667eea, #764ba2); color: white; }
.btn-primary:hover:not(:disabled) { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(102,126,234,0.4); }
.btn-primary:disabled { opacity: 0.7; cursor: not-allowed; }
.btn-secondary { background: #f1f5f9; color: #475569; }
.btn-secondary:hover { background: #e2e8f0; }
.required { color: #dc2626; }
.form-hint { color: #94a3b8; font-size: 0.8rem; margin-top: 4px; display: block; }
</style>

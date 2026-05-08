<template>
  <div class="login-page">
    <div class="login-container">
      <div class="breadcrumbs login-breadcrumbs">
        <router-link to="/">Главная</router-link> >
        <span>Вход</span>
      </div>
      <div class="login-card">
        <div class="login-header">
          <div class="logo">
            <div class="logo-icon">РБ</div>
            <div class="logo-text">
              <h1>Колледжи Башкортостана</h1>
              <p>Личный кабинет</p>
            </div>
          </div>
        </div>
        
        <form @submit.prevent="handleLogin">
          <div class="form-group">
            <label for="username">Логин</label>
            <input 
              v-model="form.username" 
              type="text" 
              id="username" 
              class="form-input" 
              placeholder="Введите логин" 
              maxlength="50"
              autocomplete="username"
              @input="form.username = maskLogin(form.username)"
              required
              :disabled="loading || isLoginLocked"
            >
          </div>
          
          <div class="form-group">
            <label for="password">Пароль</label>
            <div class="password-container">
              <input 
                :type="showPassword ? 'text' : 'password'" 
                v-model="form.password" 
                id="password" 
                class="form-input" 
                placeholder="Введите пароль" 
                maxlength="100"
                autocomplete="current-password"
                required
                :disabled="loading || isLoginLocked"
              >
              <button type="button" class="toggle-password" @click="showPassword = !showPassword">
                <i :class="showPassword ? 'fas fa-eye-slash' : 'fas fa-eye'"></i>
              </button>
            </div>
          </div>
          
          <div v-if="errorMessage" class="error-message">
            <i class="fas fa-exclamation-circle"></i> {{ errorMessage }}
          </div>
          
          <button type="submit" class="submit-btn" :disabled="loading || isLoginLocked">
            <span v-if="loading">
              <i class="fas fa-spinner fa-spin"></i> Вход...
            </span>
            <span v-else-if="isLoginLocked">
              <i class="fas fa-lock"></i> Попробуйте через {{ lockSeconds }} с
            </span>
            <span v-else>
              <i class="fas fa-sign-in-alt"></i> Войти
            </span>
          </button>
          
          <div class="login-footer">
            <router-link to="/">← Вернуться на главную</router-link>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onUnmounted, ref, reactive } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import axios from 'axios'
import { API_URL } from '../utils/api'
import { maskLogin } from '../utils/validation'

const router = useRouter()
const route = useRoute()

const form = reactive({
  username: '',
  password: ''
})

const showPassword = ref(false)
const loading = ref(false)
const errorMessage = ref('')
const lockUntil = ref(0)
const lockSeconds = ref(0)
let lockTimer = null

const isLoginLocked = computed(() => lockSeconds.value > 0)

const clearLockTimer = () => {
  if (lockTimer) {
    clearInterval(lockTimer)
    lockTimer = null
  }
}

const startLoginLock = (seconds) => {
  const duration = Math.max(Number(seconds) || 180, 1)
  lockUntil.value = Date.now() + duration * 1000

  const tick = () => {
    lockSeconds.value = Math.max(Math.ceil((lockUntil.value - Date.now()) / 1000), 0)
    if (lockSeconds.value === 0) {
      clearLockTimer()
    }
  }

  clearLockTimer()
  tick()
  lockTimer = setInterval(tick, 1000)
}

onUnmounted(clearLockTimer)

const handleLogin = async () => {
  if (isLoginLocked.value) return
  errorMessage.value = ''
  loading.value = true

  try {
    const response = await axios.post(`${API_URL}/auth/login`, {
      username: form.username,
      password: form.password
    })

    if (response.data.success) {
      const { user, token } = response.data.data

      // Сохраняем данные
      localStorage.setItem('authToken', token)
      localStorage.setItem('user', JSON.stringify(user))
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`

      console.log('✅ Вход выполнен:', user)

      // Перенаправляем в зависимости от роли
      const role = user.role?.name
      if (role === 'admin') {
        router.push('/admin')
      } else if (role === 'college_rep') {
        router.push('/college-representative')
      } else {
        const redirect = route.query.redirect || '/'
        router.push(redirect)
      }
    }

  } catch (error) {
    console.error('Login error:', error)

    if (error.response?.status === 429) {
      const retryAfter = error.response.headers?.['retry-after'] || error.response.data?.retryAfter || 180
      startLoginLock(retryAfter)
      errorMessage.value = error.response.data?.error || 'Слишком много неверных попыток. Попробуйте через 3 минуты.'
    } else if (error.response?.status === 401) {
      errorMessage.value = error.response.data.error || 'Неверный логин или пароль'
    } else if (error.request) {
      errorMessage.value = 'Нет соединения с сервером'
    } else {
      errorMessage.value = 'Произошла ошибка'
    }
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  padding: 20px;
}

.login-container {
  width: 100%;
  max-width: 450px;
}

.login-breadcrumbs {
  background: transparent;
  padding: 0 0 14px;
}

.login-card {
  background: white;
  border-radius: 16px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
  padding: 40px;
}

.login-header {
  text-align: center;
  margin-bottom: 30px;
}

.logo {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 15px;
}

.logo-icon {
  width: 60px;
  height: 60px;
  background: linear-gradient(135deg, var(--primary-blue), var(--primary-green));
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: bold;
  font-size: 1.5rem;
}

.logo-text h1 {
  font-size: 1.5rem;
  color: var(--text-dark);
  margin: 0;
}

.logo-text p {
  color: var(--text-light);
  margin: 5px 0 0 0;
  font-size: 0.9rem;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  color: var(--text-dark);
  font-weight: 500;
}

.form-input {
  width: 100%;
  padding: 12px 15px;
  border: 2px solid var(--border-color);
  border-radius: 8px;
  font-size: 1rem;
  transition: all 0.3s;
}

.form-input:focus {
  outline: none;
  border-color: var(--primary-blue);
  box-shadow: 0 0 0 3px rgba(0, 84, 166, 0.1);
}

.password-container {
  position: relative;
}

.toggle-password {
  position: absolute;
  right: 15px;
  top: 50%;
  transform: translateY(-50%);
  background: none;
  border: none;
  color: var(--text-light);
  cursor: pointer;
  font-size: 1.1rem;
}

.error-message {
  background: #ffebee;
  color: #c62828;
  padding: 12px;
  border-radius: 8px;
  margin-bottom: 20px;
  display: flex;
  align-items: center;
  gap: 10px;
  border-left: 4px solid #e74c3c;
}

.submit-btn {
  width: 100%;
  padding: 14px;
  background: linear-gradient(135deg, var(--primary-blue), var(--primary-green));
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 1.1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.submit-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 5px 15px rgba(0, 84, 166, 0.3);
}

.submit-btn:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.submit-btn i {
  margin-right: 8px;
}

.login-footer {
  margin-top: 20px;
  text-align: center;
}

.login-footer a {
  color: var(--primary-blue);
  text-decoration: none;
  transition: color 0.3s;
}

.login-footer a:hover {
  color: var(--dark-blue);
}
</style>

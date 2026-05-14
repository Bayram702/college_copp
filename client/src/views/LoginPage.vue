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
              id="username"
              v-model="form.username"
              type="text"
              class="form-input"
              placeholder="Введите логин"
              maxlength="50"
              autocomplete="username"
              :disabled="loading"
              @input="form.username = maskLogin(form.username)"
              required
            >
          </div>

          <div class="form-group">
            <label for="password">Пароль</label>
            <div class="password-container">
              <input
                id="password"
                v-model="form.password"
                :type="showPassword ? 'text' : 'password'"
                class="form-input"
                placeholder="Введите пароль"
                maxlength="100"
                autocomplete="current-password"
                :disabled="loading"
                required
              >
              <button type="button" class="toggle-password" @click="showPassword = !showPassword">
                <i :class="showPassword ? 'fas fa-eye-slash' : 'fas fa-eye'"></i>
              </button>
            </div>
          </div>

          <div v-if="errorMessage" class="error-message">
            <i class="fas fa-exclamation-circle"></i> {{ errorMessage }}
          </div>

          <button type="submit" class="submit-btn" :disabled="loading">
            <span v-if="loading">
              <i class="fas fa-spinner fa-spin"></i> Вход...
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
import { reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
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

const handleLogin = async () => {
  errorMessage.value = ''
  loading.value = true

  try {
    const response = await axios.post(`${API_URL}/auth/login`, {
      username: form.username,
      password: form.password
    })

    if (!response.data.success) {
      throw new Error(response.data.error || 'Ошибка входа')
    }

    const { user, token } = response.data.data
    localStorage.setItem('authToken', token)
    localStorage.setItem('user', JSON.stringify(user))
    axios.defaults.headers.common.Authorization = `Bearer ${token}`

    const role = user.role?.name
    if (role === 'admin') {
      router.push('/admin')
    } else if (role === 'college_rep') {
      router.push('/college-representative')
    } else {
      router.push(route.query.redirect || '/')
    }
  } catch (error) {
    console.error('Login error:', error)

    if (error.response?.status === 401) {
      errorMessage.value = error.response.data?.error || 'Неверный логин или пароль'
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
  margin: 5px 0 0;
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
  border: 2px solid #e2e8f0;
  border-radius: 10px;
  font-size: 1rem;
  transition: border-color 0.2s ease, box-shadow 0.2s ease;
}

.form-input:focus {
  outline: none;
  border-color: var(--primary-blue);
  box-shadow: 0 0 0 3px rgba(0, 84, 166, 0.12);
}

.password-container {
  position: relative;
}

.toggle-password {
  position: absolute;
  top: 50%;
  right: 12px;
  transform: translateY(-50%);
  border: none;
  background: transparent;
  cursor: pointer;
  color: #64748b;
}

.error-message {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 16px;
  padding: 12px 14px;
  border-radius: 10px;
  background: #fee2e2;
  color: #b91c1c;
  font-size: 0.95rem;
}

.submit-btn {
  width: 100%;
  padding: 14px;
  border: none;
  border-radius: 10px;
  background: var(--primary-blue);
  color: white;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.submit-btn:hover:not(:disabled) {
  transform: translateY(-1px);
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
}
</style>

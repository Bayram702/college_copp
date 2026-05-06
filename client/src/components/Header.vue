<template>
  <header>
    <div class="header-top">
      <div class="container">
        <div class="header-content">
          <div>Официальный портал колледжей Республики Башкортостан</div>
          <div>Приемная компания 2026</div>
        </div>
      </div>
    </div>
    <div class="header-main">
      <div class="container">
        <div class="header-content">
          <router-link to="/" class="logo">
            <div class="logo-icon">РБ</div>
            <div class="logo-text">Колледжи<span>Башкортостана</span></div>
          </router-link>
          <button class="mobile-menu-btn" type="button" :aria-expanded="isMobileMenuOpen" aria-label="Открыть меню" @click="isMobileMenuOpen = !isMobileMenuOpen">
            <i :class="isMobileMenuOpen ? 'fas fa-times' : 'fas fa-bars'"></i>
          </button>
          <nav class="nav-menu" :class="{ open: isMobileMenuOpen }" @click="isMobileMenuOpen = false">
            <!-- Навигация только для неавторизованных -->
            <template v-if="!currentUser">
              <router-link to="/" active-class="active">Главная</router-link>
              <router-link to="/sector" active-class="active">Специальности</router-link>
              <router-link to="/colleges" active-class="active">Колледжи</router-link>
              <router-link to="/login" class="login-btn">
                <i class="fas fa-sign-in-alt"></i> Вход
              </router-link>
            </template>
            
            <!-- Меню для авторизованных пользователей -->
            <div v-else class="user-menu">
              <template v-if="isCollegeRepresentative">
                <router-link to="/" active-class="active">Главная</router-link>
                <router-link to="/colleges" active-class="active">Колледжи</router-link>
                <router-link to="/sector" active-class="active">Специальности</router-link>
              </template>
              <router-link
                :to="userDashboardLink"
                class="user-panel-btn"
                :class="{ 'college-rep-panel-btn': isCollegeRepresentative, 'admin-panel-btn': isAdmin }"
              >
                <i class="fas fa-user-circle"></i> {{ currentUser.name }}
              </router-link>
              <button class="logout-btn" @click="logout" title="Выйти">
                <i class="fas fa-sign-out-alt"></i>
              </button>
            </div>
          </nav>
        </div>
      </div>
    </div>
  </header>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const currentUser = ref(null)
const isMobileMenuOpen = ref(false)

const userDashboardLink = computed(() => {
  if (!currentUser.value) return '/'
  const role = currentUser.value.role?.name
  if (role === 'admin') return '/admin'
  if (role === 'college_rep') return '/college-representative'
  return '/'
})

const isCollegeRepresentative = computed(() => currentUser.value?.role?.name === 'college_rep')
const isAdmin = computed(() => currentUser.value?.role?.name === 'admin')

const updateCurrentUser = () => {
  const userStr = localStorage.getItem('user')
  if (userStr) {
    try {
      currentUser.value = JSON.parse(userStr)
    } catch (e) {
      console.error('Error parsing user:', e)
      localStorage.removeItem('user')
      currentUser.value = null
    }
  } else {
    currentUser.value = null
  }
}

onMounted(() => {
  updateCurrentUser()
  window.addEventListener('focus', updateCurrentUser)
  window.addEventListener('visibilitychange', () => {
    if (!document.hidden) updateCurrentUser()
  })
})

onUnmounted(() => {
  window.removeEventListener('focus', updateCurrentUser)
})

const logout = () => {
  localStorage.removeItem('authToken')
  localStorage.removeItem('user')
  currentUser.value = null
  isMobileMenuOpen.value = false
  router.push('/login')
}
</script>

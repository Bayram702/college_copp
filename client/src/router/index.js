// router/index.js
import { createRouter, createWebHistory } from 'vue-router'
import axios from 'axios'
import HomePage from '../views/HomePage.vue'
import SpecialtiesPage from '../views/SpecialtiesPage.vue'
import CollegesPage from '../views/CollegesPage.vue'
import SpecialtyDetail from '../views/SpecialtyDetail.vue'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: HomePage
  },
  {
    path: '/sector',
    name: 'Specialties',
    component: SpecialtiesPage
  },
  {
    path: '/sectors',
    redirect: to => ({ path: '/sector', query: to.query, hash: to.hash })
  },
  {
    path: '/specialties',
    redirect: to => ({ path: '/sector', query: to.query, hash: to.hash })
  },
  {
    path: '/colleges',
    name: 'Colleges',
    component: CollegesPage
  },
  {
    path: '/specialty/:id',
    name: 'SpecialtyDetail',
    component: SpecialtyDetail
  },
  {
    path: '/college/:id',
    name: 'CollegeDetail',
    component: () => import('../views/CollegeDetail.vue')
  },
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/LoginPage.vue'),
    meta: { guestOnly: true }
  },
  {
    path: '/college-representative',
    name: 'CollegeRepresentative',
    component: () => import('../views/CollegeRepresentativePanel.vue'),
    meta: { 
      requiresAuth: true, 
      allowedRoles: ['college_rep'],
      requiresCollege: true
    }
  },
  {
    path: '/admin',
    name: 'AdminPanel',
    component: () => import('../views/AdminPanel.vue'),
    meta: { 
      requiresAuth: true, 
      allowedRoles: ['admin'] 
    }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) return savedPosition
    return { top: 0 }
  }
})

// Глобальный guard для проверки авторизации
const clearAuth = () => {
  localStorage.removeItem('authToken')
  localStorage.removeItem('user')
  delete axios.defaults.headers.common.Authorization
}

const getStoredUser = () => {
  const userStr = localStorage.getItem('user')
  if (!userStr) return null

  try {
    return JSON.parse(userStr)
  } catch (e) {
    clearAuth()
    return null
  }
}

const verifySession = async (token) => {
  axios.defaults.headers.common.Authorization = `Bearer ${token}`
  const response = await axios.get(`${API_URL}/auth/me`)
  const user = response.data?.data?.user
  if (!user) throw new Error('Пользователь не найден')
  localStorage.setItem('user', JSON.stringify(user))
  return user
}

const getDashboardRoute = (user) => {
  const role = user?.role?.name
  if (role === 'admin') return { name: 'AdminPanel' }
  if (role === 'college_rep' && user?.collegeId) return { name: 'CollegeRepresentative' }
  return { name: 'Home' }
}

// Глобальный guard для проверки авторизации
router.beforeEach(async (to, from, next) => {
  const token = localStorage.getItem('authToken')
  let user = getStoredUser()

  // Если есть токен, устанавливаем его в заголовки
  if (token) {
    axios.defaults.headers.common['Authorization'] = `Bearer ${token}`
  }

  // Если маршрут требует авторизации
  if (to.meta.requiresAuth) {
    if (!token) {
      // Не авторизован - перенаправляем на вход
      next({ name: 'Login', query: { redirect: to.fullPath } })
      return
    }

    try {
      user = await verifySession(token)
    } catch (e) {
      clearAuth()
      next({ name: 'Login', query: { redirect: to.fullPath } })
      return
    }

    // Проверяем роль
    if (to.meta.allowedRoles && !to.meta.allowedRoles.includes(user?.role?.name)) {
      // Недостаточно прав
      console.warn('⚠️ Недостаточно прав:', user?.role?.name, 'нужно:', to.meta.allowedRoles)
      next(getDashboardRoute(user))
      return
    }

    if (to.meta.requiresCollege && !user?.collegeId) {
      console.warn('⚠️ Представитель колледжа не привязан к колледжу')
      next({ name: 'Home' })
      return
    }

    next()
    return
  }

  // Если маршрут только для гостей (уже авторизованным не нужен вход)
  if (to.meta.guestOnly) {
    if (token) {
      try {
        user = await verifySession(token)
      } catch (e) {
        clearAuth()
        next()
        return
      }
      next(getDashboardRoute(user))
      return
    }
  }

  next()
})

export default router

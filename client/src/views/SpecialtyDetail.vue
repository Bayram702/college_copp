<template>
  <div class="specialty-detail-page">
    <!-- Кнопка "Наверх" -->
    <div class="back-to-top" :class="{ visible: showBackToTop }" @click="scrollToTop">
      <i class="fas fa-chevron-up"></i>
    </div>

    <!-- Состояние загрузки -->
    <div v-if="loading" class="loading-state">
      <i class="fas fa-spinner fa-spin"></i> Загрузка информации о специальности...
    </div>
    
    <!-- Состояние ошибки -->
    <div v-else-if="error" class="error-state">
      <i class="fas fa-exclamation-triangle"></i> {{ error }}
      <button @click="fetchSpecialty" class="btn-retry">Повторить</button>
    </div>

    <!-- Контент (показываем только если данные загружены) -->
    <template v-else-if="specialty">
      <!-- Путь по сайту -->
      <div class="breadcrumbs">
        <div class="container">
          <router-link to="/">Главная</router-link> > 
          <router-link to="/sector">Специальности</router-link> > 
          <span>{{ specialty.name }}</span>
        </div>
      </div>

      <!-- Заголовок специальности -->
      <section class="specialty-header">
        <div class="container">
          <h1>{{ specialty.name }}</h1>
          <p>Специальность {{ specialty.code }}. {{ specialty.description }}</p>
        </div>
      </section>

      <div class="flag-stripe"></div>

      <!-- Основной контент -->
      <div class="container">
        <!-- Основная информация о специальности -->
        <section class="section">
          <div class="section-title">
            <h2>Основная информация о специальности</h2>
          </div>
          
          <table class="specialty-info-table">
            <tbody>
              <tr>
                <th>Код и название специальности:</th>
                <td>{{ specialty.code }} "{{ specialty.name }}"</td>
              </tr>
              <tr>
                <th>Квалификация выпускника:</th>
                <td>{{ specialty.qualification }}</td>
              </tr>
            </tbody>
          </table>
        </section>

        <!-- Ссылки на специальности в других колледжах -->
        <section v-if="specialty.colleges && specialty.colleges.length > 0" class="section">
          <div class="section-title">
            <h2>Колледжи по этой специальности</h2>
          </div>
          <div class="other-colleges">
            <p>Специальность "{{ specialty.name }}" также представлена в следующих колледжах Башкортостана:</p>
            
            <div class="colleges-grid">
              <div 
                v-for="college in specialty.colleges" 
                :key="college.id" 
                class="college-card"
              >
                <img :src="college.image" :alt="college.name" class="college-image">
                <div class="college-header">
                  <i class="fas fa-university"></i>
                  <h3>{{ college.name }}</h3>
                </div>
                <div class="college-info">
                  <div class="info-row">
                    <span class="info-label">Срок обучения:</span>
                    <span class="info-value">{{ college.studyDuration }}</span>
                  </div>
                  <div class="info-row">
                    <span class="info-label">Форма обучения:</span>
                    <span class="info-value">{{ college.studyForm }}</span>
                  </div>
                  <div class="info-row">
                    <span class="info-label">База приема:</span>
                    <span class="info-value">{{ college.admissionBase }}</span>
                  </div>
                  <div class="info-row">
                    <span class="info-label">Стоимость (год):</span>
                    <span class="info-value">{{ formatPrice(college.cost) }}</span>
                  </div>
                  <div class="info-row">
                    <span class="info-label">Количество мест:</span>
                    <span class="info-value">{{ college.budgetPlaces }} бюджет / {{ college.commercialPlaces }} коммерция</span>
                  </div>
                  <div class="info-row">
                    <span class="info-label">Вступительные экзамены:</span>
                    <span class="info-value">{{ college.exams }}</span>
                  </div>
                  <div class="info-row">
                    <span class="info-label">Средний балл:</span>
                    <span class="info-value">{{ college.avgScore || '—' }}</span>
                  </div>
                  <div class="info-row">
                    <span class="info-label">Профессионалитет:</span>
                    <span class="info-value">{{ college.isProfessionalitet ? 'Участвует' : 'Не участвует' }}</span>
                  </div>
                </div>
                <div class="college-footer">
                  <router-link :to="`/college/${college.id}`" class="btn-primary" style="padding: 8px 20px; font-size: 0.9rem;">
                    Подробнее о колледже
                  </router-link>
                </div>
              </div>
            </div>
            
            <!-- Сравнительная таблица -->
            <div style="margin-top: 30px; padding: 20px; background: var(--light-bg); border-radius: 8px;">
              <h4 style="margin-bottom: 10px; color: var(--text-dark);">Сравнительная таблица по колледжам:</h4>
              <div class="table-container">
                <table class="specialty-info-table" style="font-size: 0.9rem;">
                  <thead>
                    <tr>
                      <th>Колледж</th>
                      <th>Бюджетные места</th>
                      <th>Стоимость (руб/год)</th>
                      <th>Средний балл</th>
                      <th>Профессионалитет</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="college in specialty.colleges" :key="college.id">
                      <td>{{ college.name }}</td>
                      <td>{{ college.budgetPlaces }}</td>
                      <td>{{ formatPrice(college.cost) }}</td>
                      <td>{{ college.avgScore || '—' }}</td>
                      <td>{{ college.isProfessionalitet ? 'Участвует' : 'Не участвует' }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </section>

        <!-- Перечень профессий -->
        <section v-if="specialty.careers && specialty.careers.length > 0" class="section">
          <div class="section-title">
            <h2>Кем можно работать после обучения</h2>
          </div>
          <div class="info-grid">
            <div class="info-card" v-for="(category, index) in specialty.careers" :key="index">
              <img :src="category.image" :alt="category.title" class="info-card-image">
              <div class="info-card-content">
                <h3><i :class="category.icon"></i> {{ category.title }}</h3>
                <ul class="list-items">
                  <li v-for="(item, idx) in category.items" :key="idx">
                    <i class="fas fa-check"></i> {{ item }}
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </section>

        <!-- Перечень работодателей -->
        <section v-if="specialty.employers && specialty.employers.length > 0" class="section">
          <div class="section-title">
            <h2>Работодатели-партнеры</h2>
          </div>
          <div class="info-card no-image">
            <div class="info-card-content">
              <p>Выпускники специальности "{{ specialty.name }}" востребованы на следующих предприятиях:</p>
              <ul class="list-items">
                <li v-for="(employer, index) in specialty.employers" :key="index">
                  <i class="fas fa-industry"></i> {{ employer }}
                </li>
              </ul>
            </div>
          </div>
        </section>

        <!-- Описание возможностей -->
        <section v-if="specialty.opportunities && specialty.opportunities.length > 0" class="section">
          <div class="section-title">
            <h2>Возможности для студентов</h2>
          </div>
          <div class="info-grid">
            <div class="info-card" v-for="(opportunity, index) in specialty.opportunities" :key="index">
              <img :src="opportunity.image" :alt="opportunity.title" class="info-card-image">
              <div class="info-card-content">
                <h3><i :class="opportunity.icon"></i> {{ opportunity.title }}</h3>
                <ul class="list-items">
                  <li v-for="(item, idx) in opportunity.items" :key="idx">
                    <i class="fas fa-check"></i> {{ item }}
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </section>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import axios from 'axios'
import { resolveImageUrl } from '../utils/images'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api'
const route = useRoute()

// Состояния
const specialty = ref(null)
const loading = ref(false)
const error = ref(null)
const showBackToTop = ref(false)

// Загрузка данных специальности с API
const fetchSpecialty = async () => {
  loading.value = true
  error.value = null

  try {
    const specialtyId = route.params.id
    const response = await axios.get(`${API_URL}/specialties/${specialtyId}`)

    if (response.data.success) {
      const data = response.data.data

      // Маппим данные колледжей в формат шаблона
      if (data.colleges) {
        data.colleges = data.colleges.map(c => ({
          id: c.id,
          name: c.name,
          image: resolveImageUrl(c.logo_image_url),
          studyDuration: data.duration || '—',
          studyForm: data.form === 'full-time' ? 'Очная' : data.form === 'part-time' ? 'Заочная' : 'Дистанционная',
          admissionBase: data.base_education === '9' ? '9 классов' : '11 классов',
          cost: c.price_per_year || 0,
          budgetPlaces: c.budget_places || 0,
          commercialPlaces: c.commercial_places || 0,
          exams: data.exams || '—',
          avgScore: c.avg_score || data.avg_score_last_year,
          isProfessionalitet: c.is_professionalitet,
          city: c.city_name || 'Город не указан',
          phone: c.phone,
          email: c.email,
          website: c.website
        }))
      }

      specialty.value = data
    } else {
      throw new Error(response.data.error || 'Ошибка загрузки данных')
    }
  } catch (err) {
    console.error('Ошибка при загрузке специальности:', err)
    error.value = err.message || 'Не удалось загрузить информацию о специальности'
    specialty.value = null
  } finally {
    loading.value = false
  }
}

// Вспомогательные функции
const formatPrice = (price) => {
  if (!price) return '—'
  return parseInt(price).toLocaleString('ru-RU')
}

const scrollToTop = () => {
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const handleScroll = () => {
  showBackToTop.value = window.pageYOffset > 300
}

// Хуки жизненного цикла
onMounted(() => {
  window.addEventListener('scroll', handleScroll)
  fetchSpecialty()
})

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
})
</script>

<style scoped>
.loading-state,
.error-state {
  text-align: center;
  padding: 100px 20px;
  color: var(--text-light);
  font-size: 1.1rem;
}

.loading-state i {
  font-size: 2rem;
  color: var(--primary-blue);
  margin-right: 10px;
}

.error-state {
  color: var(--danger);
}

.error-state i {
  font-size: 1.5rem;
  margin-right: 10px;
}

.btn-retry {
  margin-top: 15px;
  margin-left: 10px;
  padding: 10px 20px;
  background: var(--primary-blue);
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s;
}

.btn-retry:hover {
  background: var(--dark-blue);
}
</style>

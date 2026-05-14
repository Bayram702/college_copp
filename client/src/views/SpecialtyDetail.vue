<template>
  <div class="specialty-detail-page">
    <div v-if="loading" class="loading-state">
      <i class="fas fa-spinner fa-spin"></i> Загрузка информации о специальности...
    </div>

    <div v-else-if="error" class="error-state">
      <i class="fas fa-exclamation-triangle"></i> {{ error }}
      <button @click="fetchSpecialty" class="btn-retry">Повторить</button>
    </div>

    <template v-else-if="specialty">
      <div class="breadcrumbs">
        <div class="container">
          <router-link to="/">Главная</router-link> >
          <router-link to="/sector">Специальности</router-link> >
          <span>{{ specialty.name }}</span>
        </div>
      </div>

      <section class="specialty-header">
        <div class="container">
          <h1>{{ specialty.name }}</h1>
          <p>Специальность {{ specialty.code }}. {{ specialty.description }}</p>
        </div>
      </section>

      <div class="flag-stripe"></div>

      <div class="container">
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
                <td>{{ specialty.qualification || '—' }}</td>
              </tr>
              <tr>
                <th>Форма обучения:</th>
                <td>{{ formatStudyForm(specialty.form) }}</td>
              </tr>
              <tr>
                <th>База приема:</th>
                <td>{{ specialty.base_education === '9' ? '9 классов' : '11 классов' }}</td>
              </tr>
            </tbody>
          </table>
        </section>

        <section v-if="specialty.colleges?.length" class="section">
          <div class="section-title">
            <h2>Колледжи по этой специальности</h2>
          </div>

          <div class="colleges-grid">
            <div v-for="college in specialty.colleges" :key="college.id" class="college-card">
              <img :src="resolveImageUrl(college.logo_image_url)" :alt="college.name" class="college-image">
              <div class="college-header">
                <i class="fas fa-university"></i>
                <h3>{{ college.name }}</h3>
              </div>
              <div class="college-info">
                <div class="info-row">
                  <span class="info-label">Адрес преподавания:</span>
                  <span class="info-value">{{ college.teaching_address || '—' }}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">Стоимость (год):</span>
                  <span class="info-value">{{ formatPrice(college.price_per_year) }}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">Количество мест:</span>
                  <span class="info-value">{{ college.budget_places || 0 }} бюджет / {{ college.commercial_places || 0 }} коммерция</span>
                </div>
                <div class="info-row">
                  <span class="info-label">Средний балл:</span>
                  <span class="info-value">{{ college.avg_score || specialty.avg_score_last_year || '—' }}</span>
                </div>
              </div>
              <div class="college-footer">
                <router-link :to="`/college/${college.id}`" class="btn-primary" style="padding: 8px 20px; font-size: 0.9rem;">
                  Подробнее о колледже
                </router-link>
              </div>
            </div>
          </div>
        </section>

        <section v-if="specialty.professions?.length" class="section">
          <div class="section-title">
            <h2>Кем можно работать</h2>
          </div>
          <div class="info-card no-image">
            <div class="info-card-content">
              <ul class="list-items">
                <li v-for="(profession, index) in specialty.professions" :key="index">
                  <i class="fas fa-check"></i> {{ profession }}
                </li>
              </ul>
            </div>
          </div>
        </section>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import axios from 'axios'
import { API_URL } from '../utils/api'
import { resolveImageUrl } from '../utils/images'

const route = useRoute()
const specialty = ref(null)
const loading = ref(false)
const error = ref(null)

const fetchSpecialty = async () => {
  loading.value = true
  error.value = null

  try {
    const response = await axios.get(`${API_URL}/specialties/${route.params.id}`)
    if (!response.data.success) throw new Error(response.data.error || 'Ошибка загрузки')
    specialty.value = response.data.data
  } catch (err) {
    console.error('Ошибка загрузки специальности:', err)
    specialty.value = null
    error.value = err.message || 'Не удалось загрузить информацию о специальности'
  } finally {
    loading.value = false
  }
}

const formatPrice = (price) => {
  if (!price) return '—'
  return `${parseInt(price, 10).toLocaleString('ru-RU')} ₽`
}

const formatStudyForm = (value) => {
  if (value === 'full-time') return 'Очная'
  if (value === 'part-time') return 'Заочная'
  if (value === 'distance') return 'Дистанционная'
  return '—'
}

onMounted(fetchSpecialty)
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

.btn-retry {
  margin-top: 15px;
  margin-left: 10px;
  padding: 10px 20px;
  background: var(--primary-blue);
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
}
</style>

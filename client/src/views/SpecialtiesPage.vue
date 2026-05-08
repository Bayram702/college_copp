<template>
  <div class="specialties-page">
    <section class="hero">
      <div class="container">
        <h1>Специальности колледжей Башкортостана</h1>
        <p>Выберите направление подготовки и найдите колледжи, где есть нужная специальность.</p>
      </div>
    </section>

    <div class="flag-stripe"></div>

    <div class="breadcrumbs">
      <div class="container">
        <router-link to="/">Главная</router-link> >
        <span>Специальности</span>
      </div>
    </div>

    <section class="section">
      <div class="container">
        <div class="catalog-filters">
          <div class="filter-header">
            <h3>Отрасли</h3>
            <button class="clear-filter-btn" @click="selectSector('all')">Сбросить</button>
          </div>

          <Splide :options="splideOptions" class="sector-splide" aria-label="Фильтр по отраслям">
            <SplideSlide v-for="sector in sectors" :key="sector.id">
              <button
                class="sector-filter-card"
                :class="{ active: activeSector === sector.id }"
                type="button"
                @click="selectSector(sector.id)"
              >
                <span v-if="sector.id === 'all'" class="sector-icon"><i :class="sector.icon"></i></span>
                <span class="sector-name">{{ sector.name }}</span>
                <span v-if="sector.code" class="sector-code">{{ sector.code }}</span>
              </button>
            </SplideSlide>
          </Splide>

          <div class="catalog-search">
            <input
              v-model="searchQuery"
              type="text"
              class="search-input"
              placeholder="Поиск специальности по названию или коду..."
              @input="debouncedSearch"
              @keyup.enter="resetAndFetch"
            >
            <button class="search-button" @click="resetAndFetch">Найти</button>
          </div>

          <div class="filters-row">
            <div class="filter-group">
              <div class="filter-label">Показать</div>
              <select v-model="pageSize" class="filter-select" @change="resetAndFetch">
                <option value="9">9 специальностей</option>
                <option value="18">18 специальностей</option>
                <option value="36">36 специальностей</option>
              </select>
            </div>
          </div>
        </div>

        <div v-if="loading" class="loading-state">
          <i class="fas fa-spinner fa-spin"></i> Загрузка специальностей...
        </div>

        <div v-else-if="error" class="error-state">
          <i class="fas fa-exclamation-triangle"></i> {{ error }}
          <button @click="fetchSpecialties" class="btn-retry">Повторить</button>
        </div>

        <div v-else class="specialties-grid">
          <div v-for="specialty in specialties" :key="specialty.id" class="specialty-card">
            <div class="specialty-header">
              <div class="specialty-code">{{ specialty.code }}</div>
              <h3 class="specialty-name">{{ specialty.name }}</h3>
            </div>

            <div class="specialty-content">
              <p class="specialty-description">{{ specialty.description }}</p>

              <div class="average-score-container">
                <span class="score-label">Средний балл аттестата:</span>
                <span class="score-value">{{ specialty.avg_score || '-' }}</span>
              </div>
              <div class="average-score-container">
                <span class="score-label">Колледжей:</span>
                <span class="score-value">{{ specialty.colleges_count || 0 }}</span>
              </div>
            </div>

            <div class="specialty-footer">
              <router-link :to="`/specialty/${specialty.id}`" class="specialty-details-btn">
                Подробнее о специальности
              </router-link>
            </div>
          </div>
        </div>

        <div v-if="!loading && !error && specialties.length === 0" class="no-results">
          <p>По вашему запросу ничего не найдено. Попробуйте изменить фильтры или поиск.</p>
        </div>

        <div v-if="!loading && !error && pagination.totalPages > 1" class="pagination">
          <button class="pagination-btn" :disabled="pagination.page === 1" @click="changePage(pagination.page - 1)">
            <i class="fas fa-chevron-left"></i>
          </button>
          <button
            v-for="page in visiblePages"
            :key="page"
            class="pagination-btn"
            :class="{ active: pagination.page === page }"
            :disabled="page === '...'"
            @click="page !== '...' && changePage(page)"
          >
            {{ page }}
          </button>
          <button class="pagination-btn" :disabled="pagination.page === pagination.totalPages" @click="changePage(pagination.page + 1)">
            <i class="fas fa-chevron-right"></i>
          </button>
        </div>
      </div>
    </section>

    <section class="stats-section">
      <div class="container">
        <div class="section-title" style="color: white;">
          <h2>Статистика по специальностям</h2>
          <p>Актуальные данные по среднему профессиональному образованию.</p>
        </div>

        <div class="stats-grid">
          <div class="stat-card" v-for="stat in stats" :key="stat.id">
            <div class="stat-card-value">{{ stat.value }}</div>
            <div class="stat-card-label">{{ stat.label }}</div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import axios from 'axios'
import { Splide, SplideSlide } from '@splidejs/vue-splide'
import '@splidejs/vue-splide/css'
import { API_URL } from '../utils/api'

const route = useRoute()
const router = useRouter()

const splideOptions = {
  type: 'slide',
  rewind: false,
  gap: '12px',
  pagination: false,
  autoWidth: true,
  arrows: true,
  drag: 'free',
  snap: true
}

const sectors = ref([{ id: 'all', name: 'Все отрасли', icon: 'fas fa-th-large', code: '' }])
const activeSector = ref('all')
const searchQuery = ref('')
const specialties = ref([])
const loading = ref(false)
const error = ref(null)
const pageSize = ref('9')
const pagination = ref({ total: 0, page: 1, limit: 9, totalPages: 0 })
const stats = ref([
  { id: 1, value: '-', label: 'Специальностей СПО' },
  { id: 2, value: '-', label: 'Колледжей и техникумов' },
  { id: 3, value: '-', label: 'Средний балл по специальностям' }
])

let searchTimeout = null

const loadSectors = async () => {
  try {
    const response = await fetch(`${API_URL}/sectors`)
    const result = await response.json()
    if (result.success) {
      sectors.value = [
        { id: 'all', name: 'Все отрасли', icon: 'fas fa-th-large', code: '' },
        ...result.data.map(sector => ({
          id: String(sector.id),
          name: sector.name,
          code: sector.code
        }))
      ]
    }
  } catch (err) {
    console.error('Ошибка загрузки отраслей:', err)
  }
}

const loadStats = async () => {
  try {
    const response = await fetch(`${API_URL}/colleges/stats`)
    const result = await response.json()
    if (result.success) {
      const { colleges, specialties: specStats } = result.data
      stats.value = [
        { id: 1, value: specStats.total_specialties || '-', label: 'Специальностей СПО' },
        { id: 2, value: colleges.active_colleges || '-', label: 'Колледжей и техникумов' },
        { id: 3, value: specStats.avg_score_last_year || '-', label: 'Средний балл по специальностям' }
      ]
    }
  } catch (err) {
    console.error('Ошибка загрузки статистики:', err)
  }
}

const fetchSpecialties = async () => {
  loading.value = true
  error.value = null

  try {
    const params = new URLSearchParams()
    if (activeSector.value !== 'all') params.append('sector_id', activeSector.value)
    if (searchQuery.value.trim()) params.append('search', searchQuery.value.trim())
    params.append('limit', pageSize.value)
    params.append('page', pagination.value.page)

    const response = await axios.get(`${API_URL}/specialties?${params.toString()}`)
    if (!response.data.success) throw new Error(response.data.error || 'Ошибка загрузки данных')

    specialties.value = response.data.data
    pagination.value = response.data.pagination
  } catch (err) {
    console.error('Ошибка загрузки специальностей:', err)
    error.value = err.message || 'Не удалось загрузить специальности'
    specialties.value = []
  } finally {
    loading.value = false
  }
}

const visiblePages = computed(() => {
  const total = pagination.value.totalPages
  const current = pagination.value.page
  if (total <= 7) return Array.from({ length: total }, (_, index) => index + 1)
  if (current <= 4) return [1, 2, 3, 4, 5, '...', total]
  if (current >= total - 3) return [1, '...', total - 4, total - 3, total - 2, total - 1, total]
  return [1, '...', current - 1, current, current + 1, '...', total]
})

const resetAndFetch = () => {
  pagination.value.page = 1
  fetchSpecialties()
}

const selectSector = (sectorId) => {
  activeSector.value = String(sectorId)
  pagination.value.page = 1
  const query = { ...route.query }
  if (activeSector.value === 'all') delete query.sector_id
  else query.sector_id = activeSector.value
  router.replace({ query })
  fetchSpecialties()
}

const changePage = (page) => {
  if (page < 1 || page > pagination.value.totalPages) return
  pagination.value.page = page
  fetchSpecialties()
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const debouncedSearch = () => {
  clearTimeout(searchTimeout)
  searchTimeout = setTimeout(resetAndFetch, 300)
}

const syncSectorFromRoute = () => {
  activeSector.value = route.query.sector_id ? String(route.query.sector_id) : 'all'
}

onMounted(async () => {
  syncSectorFromRoute()
  await Promise.all([loadSectors(), loadStats()])
  fetchSpecialties()
})

watch(() => route.query.sector_id, (sectorId) => {
  const normalized = sectorId ? String(sectorId) : 'all'
  if (normalized === activeSector.value) return
  activeSector.value = normalized
  resetAndFetch()
})
</script>

<style scoped>
.loading-state,
.error-state {
  text-align: center;
  padding: 60px 20px;
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
  padding: 10px 20px;
  background: var(--primary-blue);
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
}

.no-results {
  text-align: center;
  padding: 60px 20px;
  color: var(--text-light);
  font-size: 1.1rem;
  background: white;
  border-radius: 8px;
  margin-top: 20px;
}
</style>

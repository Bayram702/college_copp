<template>
  <div class="colleges-page">
    <div class="back-to-top" :class="{ visible: showBackToTop }" @click="scrollToTop">
      <i class="fas fa-chevron-up"></i>
    </div>

    <section class="hero">
      <div class="container">
        <h1>Колледжи Башкортостана</h1>
        <p>Все средние профессиональные учебные заведения республики с программами, контактами и условиями приема.</p>
      </div>
    </section>

    <div class="flag-stripe"></div>

    <div class="breadcrumbs">
      <div class="container">
        <router-link to="/">Главная</router-link> >
        <span>Колледжи</span>
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
                :class="{ active: filters.sector_id === sector.id }"
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
              placeholder="Поиск по названию колледжа, городу или описанию..."
              @input="debouncedSearch"
              @keyup.enter="resetPagination"
            >
            <button class="search-button" @click="resetPagination">Найти</button>
          </div>

          <div class="filters-row">
            <div class="filter-group">
              <div class="filter-label">Город/район</div>
              <select v-model="filters.city" class="filter-select" @change="resetPagination">
                <option value="all">Все города</option>
                <option value="Уфа">Уфа</option>
                <option value="Стерлитамак">Стерлитамак</option>
                <option value="Салават">Салават</option>
                <option value="Нефтекамск">Нефтекамск</option>
                <option value="Октябрьский">Октябрьский</option>
                <option value="Белорецк">Белорецк</option>
                <option value="Ишимбай">Ишимбай</option>
                <option value="Кумертау">Кумертау</option>
              </select>
            </div>

            <div class="filter-group">
              <div class="filter-label">Профессионалитет</div>
              <select v-model="filters.professionalitet" class="filter-select" @change="resetPagination">
                <option value="all">Все колледжи</option>
                <option value="yes">Участвует</option>
                <option value="no">Не участвует</option>
              </select>
            </div>

            <div class="filter-group">
              <div class="filter-label">Показать</div>
              <select v-model="showCount" class="filter-select" @change="updateShowCount">
                <option value="6">6 колледжей</option>
                <option value="12">12 колледжей</option>
                <option value="24">24 колледжа</option>
              </select>
            </div>
          </div>
        </div>

        <div v-if="loading" class="loading-state">
          <i class="fas fa-spinner fa-spin"></i> Загрузка колледжей...
        </div>

        <div v-else-if="error" class="error-state">
          <i class="fas fa-exclamation-triangle"></i> {{ error }}
          <button @click="fetchColleges" class="btn-retry">Повторить</button>
        </div>

        <div v-else class="colleges-grid">
          <div
            v-for="college in colleges"
            :key="college.id"
            class="college-card"
            :class="{ professionalitet: college.is_professionalitet }"
          >
            <div class="college-header">
              <img :src="resolveImageUrl(college.logo_image_url)" :alt="college.name" class="college-image">
              <div v-if="college.is_professionalitet" class="professionalitet-badge">
                <i class="fas fa-check-circle"></i> Профессионалитет
              </div>
            </div>

            <div class="college-content">
              <h3 class="college-title">{{ college.name }}</h3>

              <div class="college-location">
                <i class="fas fa-map-marker-alt"></i> {{ college.city_name || college.city }}
              </div>

              <p class="college-description">{{ college.description }}</p>

              <div class="admission-stats">
                <div class="stats-title">Статистика приема</div>
                <div class="stats-grid">
                  <div class="stat-item">
                    <div class="stat-value">{{ college.budget_places || 0 }}</div>
                    <div class="stat-label">Бюджетных мест</div>
                  </div>
                  <div class="stat-item">
                    <div class="stat-value">{{ college.commercial_places || 0 }}</div>
                    <div class="stat-label">Коммерческих мест</div>
                  </div>
                  <div class="stat-item">
                    <div class="stat-value">{{ college.avg_score || '-' }}</div>
                    <div class="stat-label">Средний балл</div>
                  </div>
                  <div class="stat-item">
                    <div class="stat-value">{{ college.min_score || '-' }}</div>
                    <div class="stat-label">Минимальный балл</div>
                  </div>
                </div>
              </div>
            </div>

            <div class="college-footer">
              <router-link :to="`/college/${college.id}`" class="btn-details">Подробнее о колледже</router-link>
            </div>
          </div>
        </div>

        <div v-if="!loading && !error && colleges.length === 0" class="no-results">
          <p>По вашему запросу ничего не найдено. Попробуйте изменить фильтры.</p>
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
  </div>
</template>

<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue'
import axios from 'axios'
import { Splide, SplideSlide } from '@splidejs/vue-splide'
import '@splidejs/vue-splide/css'
import { API_URL } from '../utils/api'
import { resolveImageUrl } from '../utils/images'

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
const colleges = ref([])
const loading = ref(false)
const error = ref(null)
const showBackToTop = ref(false)
const searchQuery = ref('')
const showCount = ref('6')
const filters = ref({ city: 'all', sector_id: 'all', professionalitet: 'all' })
const pagination = ref({ total: 0, page: 1, limit: 6, totalPages: 0 })

let searchTimeout = null

const loadSectors = async () => {
  try {
    const response = await fetch(`${API_URL}/sectors`)
    const result = await response.json()
    if (result.success) {
      sectors.value = [
        { id: 'all', name: 'Все отрасли', icon: 'fas fa-th-large', code: '' },
        ...result.data
          .map(sector => ({
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

const fetchColleges = async () => {
  loading.value = true
  error.value = null

  try {
    const params = new URLSearchParams()
    if (filters.value.city !== 'all') params.append('city', filters.value.city)
    if (filters.value.sector_id !== 'all') params.append('sector_id', filters.value.sector_id)
    if (filters.value.professionalitet !== 'all') params.append('professionalitet', filters.value.professionalitet)
    if (searchQuery.value.trim()) params.append('search', searchQuery.value.trim())
    params.append('limit', showCount.value)
    params.append('page', pagination.value.page)

    const response = await axios.get(`${API_URL}/colleges?${params.toString()}`)
    if (!response.data.success) throw new Error(response.data.error || 'Ошибка загрузки данных')

    colleges.value = response.data.data
    pagination.value = response.data.pagination
  } catch (err) {
    console.error('Ошибка загрузки колледжей:', err)
    error.value = err.message || 'Не удалось загрузить колледжи'
    colleges.value = []
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

const resetPagination = () => {
  pagination.value.page = 1
  fetchColleges()
}

const selectSector = (sectorId) => {
  filters.value.sector_id = String(sectorId)
  resetPagination()
}

const updateShowCount = () => {
  pagination.value.limit = parseInt(showCount.value, 10)
  resetPagination()
}

const changePage = (page) => {
  if (page < 1 || page > pagination.value.totalPages) return
  pagination.value.page = page
  fetchColleges()
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const debouncedSearch = () => {
  clearTimeout(searchTimeout)
  searchTimeout = setTimeout(resetPagination, 300)
}

const scrollToTop = () => {
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const handleScroll = () => {
  showBackToTop.value = window.pageYOffset > 300
}

onMounted(async () => {
  window.addEventListener('scroll', handleScroll)
  await loadSectors()
  fetchColleges()
})

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
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
  margin-left: 15px;
}
</style>

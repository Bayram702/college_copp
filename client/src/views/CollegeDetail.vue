<template>
  <div class="college-detail-page">
    <!-- Кнопка "Наверх" -->
    <div class="back-to-top" :class="{ visible: showBackToTop }" @click="scrollToTop">
      <i class="fas fa-chevron-up"></i>
    </div>

    <!-- Состояние загрузки -->
    <div v-if="loading" class="loading-state">
      <i class="fas fa-spinner fa-spin"></i> Загрузка информации о колледже...
    </div>
    
    <!-- Состояние ошибки -->
    <div v-else-if="error" class="error-state">
      <i class="fas fa-exclamation-triangle"></i> {{ error }}
      <button @click="fetchCollege" class="btn-retry">Повторить</button>
    </div>

    <!-- Контент (показываем только если данные загружены) -->
    <template v-else-if="college">
      <!-- Путь по сайту -->
      <div class="breadcrumbs">
        <div class="container">
          <router-link to="/">Главная</router-link> > 
          <router-link to="/colleges">Колледжи</router-link> > 
          <span>{{ college.name }}</span>
        </div>
      </div>

      <!-- Заголовок колледжа -->
      <section class="college-header">
        <div class="container">
          <div class="header-content">
            <div class="header-info">
              <h1>{{ college.name }}</h1>
              <p v-if="college.city" class="header-city">
                <i class="fas fa-map-marker-alt"></i> {{ college.city }}
              </p>
            </div>
          </div>
        </div>
      </section>

      <div class="flag-stripe"></div>

      <!-- Основной контент -->
      <div class="container">
        <!-- Карусель фотографий (если есть) -->
        <section v-if="college.photos && college.photos.length > 0" class="photo-carousel">
          <div class="carousel-container">
            <div 
              v-for="(photo, index) in college.photos" 
              :key="index"
              class="carousel-slide"
              :class="{ active: currentSlide === index }"
            >
              <img :src="photo.image" :alt="photo.title">
              <div class="carousel-caption">
                <h3>{{ photo.title }}</h3>
                <p>{{ photo.description }}</p>
              </div>
            </div>
            
            <button class="carousel-btn carousel-prev" @click="prevSlide">❮</button>
            <button class="carousel-btn carousel-next" @click="nextSlide">❯</button>
            
            <div class="carousel-nav">
              <div 
                v-for="(photo, index) in college.photos" 
                :key="index"
                class="carousel-dot"
                :class="{ active: currentSlide === index }"
                @click="goToSlide(index)"
              ></div>
            </div>
          </div>
        </section>

        <!-- Перечень специальностей -->
        <section v-if="college.specialties && college.specialties.length > 0" class="section">
          <div class="section-title">
            <h2>Специальности</h2>
          </div>
          <div class="table-container">
            <table class="specialties-table">
              <thead>
                <tr>
                  <th>Код</th>
                  <th>Специальность</th>
                  <th>Вступительные экзамены</th>
                  <th>База</th>
                  <th>Стоимость (руб/год)</th>
                  <th>Бюджет/Коммерция</th>
                  <th>Ср. балл</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="specialty in college.specialties" :key="specialty.id">
                  <td>{{ specialty.code }}</td>
                  <td>
                    <router-link :to="`/specialty/${specialty.id}`">
                      {{ specialty.name }}
                    </router-link>
                  </td>
                  <td>{{ specialty.exams || '—' }}</td>
                  <td>{{ formatBase(specialty.base_education) }}</td>
                  <td>{{ formatPrice(specialty.price_per_year) }}</td>
                  <td>{{ specialty.budget_places || 0 }}/{{ specialty.commercial_places || 0 }}</td>
                  <td>{{ specialty.avg_score || specialty.avg_score_last_year || '—' }}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <div style="margin-top: 20px;">
            <p><strong>Примечание:</strong> В столбце "Бюджет/Коммерция" указано количество бюджетных/коммерческих мест.</p>
          </div>
        </section>

        <!-- Краткая статистика -->
        <section v-if="college.statistics" class="section">
          <div class="section-title">
            <h2>Статистика приема 2025</h2>
          </div>
          <div class="stats-grid">
            <div class="stat-item" v-for="stat in college.statistics" :key="stat.label">
              <div class="stat-value">{{ stat.value }}</div>
              <div class="stat-label">{{ stat.label }}</div>
            </div>
          </div>
        </section>

        <!-- Перечень профессий -->
        <section v-if="careers.length > 0" class="section">
          <div class="section-title">
            <h2>Кем можно работать после обучения</h2>
          </div>
          <div class="info-card no-image">
            <div class="info-card-content">
              <ul class="list-items">
                <li v-for="(career, index) in careers" :key="index">
                  <i class="fas fa-briefcase"></i> {{ career }}
                </li>
              </ul>
            </div>
          </div>
        </section>

        <!-- Возможности в колледже -->
        <section v-if="opportunities.length > 0" class="section">
          <div class="section-title">
            <h2>Возможности в колледже</h2>
          </div>
          <div class="info-card no-image">
            <div class="info-card-content">
              <ul class="list-items">
                <li v-for="(item, index) in opportunities" :key="index">
                  <i class="fas fa-star"></i> {{ item }}
                </li>
              </ul>
            </div>
          </div>
        </section>

        <!-- Перечень работодателей -->
        <section v-if="college.employers && college.employers.length > 0" class="section">
          <div class="section-title">
            <h2>Работодатели-партнеры</h2>
          </div>
          <div class="info-card no-image">
            <div class="info-card-content">
              <ul class="list-items">
                <li v-for="(employer, index) in college.employers" :key="index">
                  <i class="fas fa-industry"></i> {{ employer }}
                </li>
              </ul>
            </div>
          </div>
        </section>

        <!-- Учебные мастерские и лаборатории -->
        <section v-if="college.workshops && college.workshops.length > 0" class="section">
          <div class="section-title">
            <h2>Учебные мастерские и лаборатории</h2>
          </div>
          <div class="info-card no-image">
            <div class="info-card-content">
              <ul class="list-items">
                <li v-for="(workshop, index) in college.workshops" :key="index">
                  <i class="fas fa-flask"></i> {{ workshop }}
                </li>
              </ul>
            </div>
          </div>
        </section>

        <!-- Программы для людей с ОВЗ -->
        <section v-if="college.ovzPrograms && college.ovzPrograms.length > 0" class="section">
          <div class="section-title">
            <h2>Программы для людей с ОВЗ</h2>
          </div>
          <div class="info-card no-image">
            <div class="info-card-content">
              <p>Колледж создает специальные условия для получения образования лицами с ограниченными возможностями здоровья:</p>
              <ul class="list-items">
                <li v-for="(item, index) in college.ovzPrograms" :key="index">
                  <i class="fas fa-universal-access"></i> {{ item }}
                </li>
              </ul>
            </div>
          </div>
        </section>

        <!-- Адреса расположения -->
        <section v-if="college.campuses && college.campuses.length > 0" class="section">
          <div class="section-title">
            <h2>Адреса расположения</h2>
          </div>
          <div class="info-grid">
            <div class="info-card" v-for="(campus, index) in college.campuses" :key="index">
              <img :src="campus.image" :alt="campus.name" class="info-card-image" v-if="campus.image">
              <div class="info-card-content">
                <h3><i class="fas fa-map-marker-alt"></i> {{ campus.name }}</h3>
                <p>{{ campus.address }}</p>
                <p v-if="campus.phone">Телефон: {{ campus.phone }}</p>
                <p v-if="campus.email">Email: {{ campus.email }}</p>
                <p v-if="campus.is_main" style="color: #4CAF50; font-weight: bold; margin-top: 8px;">✓ Главный корпус</p>
              </div>
            </div>
          </div>

          <!-- Карта с метками -->
          <div class="map-container" style="margin-top: 40px;">
            <div v-if="mapLoading" class="map-loading">
              <i class="fas fa-spinner fa-spin"></i> Загрузка карты...
            </div>
            <div v-else-if="mapError" class="map-error">
              <i class="fas fa-exclamation-triangle"></i> {{ mapError }}
            </div>
            <div v-else id="college-map"></div>
          </div>
        </section>

        <section v-if="collegeContactItems.length > 0" class="section">
          <div class="section-title">
            <h2>Связь с колледжем</h2>
          </div>
          <div class="sources-grid">
            <a
              v-for="item in collegeContactItems"
              :key="item.key"
              :href="item.href"
              :target="item.target"
              :rel="item.target === '_blank' ? 'noopener noreferrer' : null"
              class="source-card"
            >
              <span class="source-label">{{ item.label }}</span>
              <span class="source-url">{{ item.value }}</span>
            </a>
          </div>
        </section>

      </div>
    </template>
  </div>
</template>

<script setup>
import { computed, ref, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useRoute } from 'vue-router'
import axios from 'axios'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api'
const route = useRoute()

// Состояния
const college = ref(null)
const loading = ref(false)
const error = ref(null)
const showBackToTop = ref(false)
const currentSlide = ref(0)
const mapLoading = ref(false)
const mapError = ref(null)
let slideInterval = null
let collegeMap = null

// Карьерные возможности и возможности обучения загружаются из БД через college.value
// Сервер возвращает: opportunities, employers, workshops, professions, ovz_programs
const careers = ref([])
const opportunities = ref([])

const normalizeSocialOther = (value) => {
  if (!value) return []
  if (Array.isArray(value)) {
    return value
      .map(item => typeof item === 'string' ? item : item?.url || item?.value || '')
      .filter(Boolean)
  }
  if (typeof value === 'object') {
    return Object.values(value).filter(item => typeof item === 'string' && item.trim())
  }
  if (typeof value === 'string') {
    return value.split('\n').map(item => item.trim()).filter(Boolean)
  }
  return []
}

const collegeContactItems = computed(() => {
  if (!college.value) return []

  const items = [
    {
      key: 'phone',
      label: 'Телефон',
      value: college.value.phone,
      href: college.value.phone ? `tel:${college.value.phone}` : null,
      target: '_self'
    },
    {
      key: 'email',
      label: 'Электронная почта',
      value: college.value.email,
      href: college.value.email ? `mailto:${college.value.email}` : null,
      target: '_self'
    },
    {
      key: 'website',
      label: 'Сайт колледжа',
      value: college.value.website,
      href: college.value.website,
      target: '_blank'
    },
    {
      key: 'social_vk',
      label: 'ВКонтакте',
      value: college.value.social_vk,
      href: college.value.social_vk,
      target: '_blank'
    },
    {
      key: 'social_max',
      label: 'MAX',
      value: college.value.social_max,
      href: college.value.social_max,
      target: '_blank'
    }
  ].filter(item => item.value)

  const otherSources = normalizeSocialOther(college.value.social_other).map((url, index) => ({
    key: `social_other_${index}`,
    label: `Соцсеть ${index + 1}`,
    value: url,
    href: url,
    target: '_blank'
  }))

  return [...items, ...otherSources]
})

// Загрузка данных колледжа с API
const fetchCollege = async () => {
  loading.value = true
  error.value = null

  try {
    const collegeId = route.params.id
    const response = await axios.get(`${API_URL}/colleges/${collegeId}`)

    if (response.data.success) {
      college.value = response.data.data
      // Загружаем возможности и карьеры из данных колледжа
      if (response.data.data.opportunities) {
        opportunities.value = response.data.data.opportunities
      }
      if (response.data.data.employers) {
        careers.value = response.data.data.employers
      }
      
      // Инициализируем карту после загрузки данных
      if (response.data.data.campuses && response.data.data.campuses.length > 0) {
        await nextTick()
        setTimeout(() => {
          initMap()
        }, 200)
      }
    } else {
      throw new Error(response.data.error || 'Ошибка загрузки данных')
    }
  } catch (err) {
    console.error('Ошибка при загрузке колледжа:', err)
    error.value = err.message || 'Не удалось загрузить информацию о колледже'
    college.value = null
  } finally {
    loading.value = false
  }
}

// Вспомогательные функции
const formatPrice = (price) => {
  if (!price || price === 0) return 'Бесплатно'
  return parseInt(price).toLocaleString('ru-RU')
}

const formatBase = (base) => {
  if (!base) return '—'
  return base === '9' ? '9 классов' : '11 классов'
}

const formatForm = (form) => {
  if (!form) return '—'
  const formMap = {
    'full-time': 'Очная',
    'part-time': 'Заочная',
    'distance': 'Дистанционная'
  }
  return formMap[form] || form
}

const formatDuration = (duration) => {
  if (!duration) return '—'
  return duration
}

// Методы карусели
const nextSlide = () => {
  if (college.value && college.value.photos) {
    currentSlide.value = (currentSlide.value + 1) % college.value.photos.length
  }
}

const prevSlide = () => {
  if (college.value && college.value.photos) {
    currentSlide.value = (currentSlide.value - 1 + college.value.photos.length) % college.value.photos.length
  }
}

const goToSlide = (index) => {
  currentSlide.value = index
}

const startSlideShow = () => {
  slideInterval = setInterval(nextSlide, 5000)
}

const stopSlideShow = () => {
  if (slideInterval) {
    clearInterval(slideInterval)
  }
}

const scrollToTop = () => {
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const handleScroll = () => {
  showBackToTop.value = window.pageYOffset > 300
}

// Загрузка Yandex Maps API
const loadYandexMaps = () => {
  return new Promise((resolve, reject) => {
    if (window.ymaps) {
      window.ymaps.ready(() => resolve(window.ymaps))
      return
    }

    const script = document.createElement('script')
    script.src = 'https://api-maps.yandex.ru/2.1/?lang=ru_RU'
    script.type = 'text/javascript'
    script.onload = () => {
      window.ymaps.ready(() => resolve(window.ymaps))
    }
    script.onerror = (e) => {
      console.error('❌ Ошибка загрузки Yandex Maps API:', e)
      reject(new Error('Не удалось загрузить Yandex Maps API'))
    }
    document.head.appendChild(script)
  })
}

// Парсинг координат
const parseCoordinates = (coordsString) => {
  if (!coordsString) return null
  
  try {
    const cleaned = coordsString.replace(/[\[\]"'\s]/g, '')
    const parts = cleaned.split(',').map(s => parseFloat(s.trim()))
    
    if (parts.length === 2 && !isNaN(parts[0]) && !isNaN(parts[1])) {
      return [parts[0], parts[1]]
    }
  } catch (e) {
    console.error('❌ Ошибка парсинга координат:', coordsString, e)
  }
  
  return null
}

// Инициализация карты
const initMap = async () => {
  if (!college.value || !college.value.campuses || college.value.campuses.length === 0) {
    console.warn('⚠️ Нет адресов для отображения на карте')
    return
  }

  try {
    mapError.value = null
    
    // Загружаем Yandex Maps API
    await loadYandexMaps()
    
    // Находим первый кампус с координатами для центра карты
    const firstCampus = college.value.campuses.find(c => c.coordinates)
    if (!firstCampus) {
      mapError.value = 'Нет координат для отображения'
      return
    }

    const centerCoords = parseCoordinates(firstCampus.coordinates)
    if (!centerCoords) {
      mapError.value = 'Не удалось распознать координаты'
      return
    }

    // Сначала показываем контейнер карты (убираем loading)
    mapLoading.value = false
    await nextTick()
    await new Promise(resolve => setTimeout(resolve, 150))
    
    // Проверяем, что элемент существует
    const mapElement = document.getElementById('college-map')
    if (!mapElement) {
      console.error('❌ Элемент карты не найден в DOM')
      mapError.value = 'Контейнер карты не найден'
      return
    }

    // Создаём карту
    collegeMap = new window.ymaps.Map('college-map', {
      center: centerCoords,
      zoom: 14,
      controls: ['zoomControl', 'fullscreenControl']
    }, {
      searchControlProvider: 'yandex#search'
    })

    // Добавляем метки для каждого адреса
    let placemarksCount = 0
    
    college.value.campuses.forEach((campus, index) => {
      if (!campus.coordinates) {
        console.warn(`⚠️ Пропущен адрес без координат: ${campus.name || campus.address}`)
        return
      }

      const coords = parseCoordinates(campus.coordinates)
      if (!coords) {
        console.warn(`⚠️ Не удалось распарсить координаты: ${campus.coordinates}`)
        return
      }

      const isMain = campus.is_main
      const placemark = new window.ymaps.Placemark(coords, {
        balloonContentHeader: `<strong style="font-size:14px; color:#0054A6;">${campus.name || 'Корпус колледжа'}</strong>`,
        balloonContentBody: `
          <div style="max-width:280px; padding:4px;">
            <p style="margin:6px 0; color:#333; font-size:13px;">
              <strong style="color:#0054A6;">📍 Адрес:</strong><br>
              ${campus.address || 'Адрес не указан'}
            </p>
            ${campus.phone ? `
              <p style="margin:6px 0; font-size:13px;">
                <strong style="color:#0054A6;">📞 Телефон:</strong><br>
                <a href="tel:${campus.phone}" style="color:#0054A6; text-decoration:none;">${campus.phone}</a>
              </p>
            ` : ''}
            ${campus.email ? `
              <p style="margin:6px 0; font-size:13px;">
                <strong style="color:#0054A6;">📧 Email:</strong><br>
                <a href="mailto:${campus.email}" style="color:#0054A6; text-decoration:none;">${campus.email}</a>
              </p>
            ` : ''}
            ${isMain ? '<p style="margin:6px 0; font-size:12px; color:#4CAF50;"><strong>✓ Главный корпус</strong></p>' : ''}
          </div>
        `,
        hintContent: campus.name || campus.address
      }, {
        preset: isMain ? 'islands#blueEducationCircleIcon' : 'islands#lightBlueCircleIcon',
        iconColor: isMain ? '#0054A6' : '#2196F3'
      })
      
      collegeMap.geoObjects.add(placemark)
      placemarksCount++
    })

    // Автомасштабирование, если есть несколько меток
    if (placemarksCount > 1) {
      const bounds = collegeMap.geoObjects.getBounds()
      if (bounds) {
        collegeMap.setBounds(bounds, {
          checkZoomRange: true,
          zoomMargin: 50,
          duration: 300
        })
      }
    }

    console.log(`✅ Карта инициализирована с ${placemarksCount} метками`)
    
  } catch (err) {
    console.error('❌ Ошибка инициализации карты:', err)
    mapError.value = 'Не удалось загрузить карту'
    mapLoading.value = false
  }
}

// Очистка карты
const destroyMap = () => {
  if (collegeMap) {
    collegeMap.destroy()
    collegeMap = null
  }
}

// Наблюдение за изменением маршрута (для перезагрузки при смене колледжа)
watch(() => route.params.id, () => {
  destroyMap()
  fetchCollege()
})

onMounted(() => {
  window.addEventListener('scroll', handleScroll)
  fetchCollege()

  // Инициализация карусели
  const stopWatch = setInterval(() => {
    if (college.value) {
      startSlideShow()
      clearInterval(stopWatch)
    }
  }, 100)
})

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
  stopSlideShow()
  destroyMap()
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

/* Стили для карты */
.map-container {
  width: 100%;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  background: white;
}

#college-map {
  width: 100%;
  height: 500px;
}

.map-loading,
.map-error {
  text-align: center;
  padding: 80px 20px;
  color: #666;
  font-size: 16px;
  background: #f5f5f5;
  border-radius: 12px;
}

.map-loading i {
  font-size: 2.5rem;
  color: #0054A6;
  margin-bottom: 15px;
  display: block;
  animation: spin 1s linear infinite;
}

.map-error {
  color: #d32f2f;
  background: #ffebee;
}

.map-error i {
  font-size: 2rem;
  margin-bottom: 10px;
  display: block;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

/* Стили для заголовка колледжа с логотипом */
.college-header {
  padding: 40px 0;
  background: linear-gradient(135deg, var(--primary-blue), var(--primary-green));
  margin-bottom: 30px;
}

.college-header .header-content {
  display: flex;
  justify-content: center;
}

.college-header .header-info {
  max-width: 900px;
  text-align: center;
}

.college-header h1 {
  margin: 0 0 15px 0;
  font-size: 2.5rem;
  color: white;
  line-height: 1.2;
}

.college-header .header-city {
  margin: 0;
  font-size: 1.1rem;
  color: rgba(255, 255, 255, 0.9);
  display: flex;
  align-items: center;
  gap: 8px;
}

.college-header .header-city i {
  color: white;
}

.sources-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 16px;
}

.source-card {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 18px 20px;
  border-radius: 12px;
  background: white;
  border: 1px solid var(--border-color);
  color: inherit;
  text-decoration: none;
  transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease;
}

.source-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 10px 24px rgba(0, 0, 0, 0.08);
  border-color: var(--primary-blue);
}

.source-label {
  font-weight: 700;
  color: var(--text-dark);
}

.source-url {
  color: var(--primary-blue);
  word-break: break-word;
}

/* Адаптивность для заголовка */
@media (max-width: 768px) {
  .college-header .header-content {
    justify-content: center;
  }

  .college-header h1 {
    font-size: 2rem;
  }

  .college-header .header-city {
    justify-content: center;
  }
}

/* Адаптивность для карты */
@media (max-width: 768px) {
  #college-map {
    height: 400px;
  }
  
  .map-loading,
  .map-error {
    padding: 60px 20px;
  }
}
</style>

<template>
  <section class="section map-section">
    <div class="container">
      <div class="section-title">
        <h2>Колледжи на карте Башкортостана</h2>
        <p>Найдите колледжи по всей территории Республики Башкортостан</p>
      </div>

      <div v-if="loading" class="loading-map">
        <i class="fas fa-spinner fa-spin"></i> Загрузка карты...
      </div>

      <div v-else-if="error" class="map-error">
        <p>{{ error }}</p>
      </div>

      <div v-else class="map-container">
        <div ref="mapContainer" id="map"></div>
      </div>
    </div>
  </section>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { apiPath } from '../utils/api'

const mapContainer = ref(null)
const colleges = ref([])
const loading = ref(true)
const error = ref(null)

let myMap = null
let placemarks = []

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

// Загрузка колледжей с API
const loadCollegesFromAPI = async () => {
  try {
    console.log('📡 Загрузка колледжей для карты...')
    const response = await fetch(apiPath('/colleges/map'))
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
    
    const result = await response.json()
    
    if (result.success) {
      colleges.value = result.data.filter(c => c.addresses && c.addresses.length > 0)
      
      console.log('✅ Загружено колледжей для карты:', colleges.value.length)
      colleges.value.forEach(c => {
        console.log(`  🏫 ${c.name} (${c.addresses.length} адресов)`)
        c.addresses.forEach(addr => {
          console.log(`    📍 ${addr.address_name || addr.address}: ${addr.coordinates} -> ${parseCoordinates(addr.coordinates)}`)
        })
      })
      
      if (colleges.value.length === 0) {
        console.warn('⚠️ Нет колледжей с валидными координатами')
      }
    } else {
      throw new Error(result.error || 'Ошибка получения данных')
    }
  } catch (err) {
    console.error('❌ Ошибка загрузки колледжей:', err)
    throw err
  }
}

// Парсинг координат из строки
const parseCoordinates = (coordsString) => {
  if (!coordsString) return null
  
  try {
    // Ожидаем формат "широта,долгота" или "[широта,долгота]"
    const cleaned = coordsString.replace(/[\[\]"'\s]/g, '')
    const parts = cleaned.split(',').map(s => parseFloat(s.trim()))
    
    if (parts.length === 2 && !isNaN(parts[0]) && !isNaN(parts[1])) {
      // Проверяем, что координаты в пределах Башкортостана
      const [lat, lon] = parts
      if (lat >= 51 && lat <= 56 && lon >= 53 && lon <= 60) {
        return [lat, lon]
      } else {
        console.warn(`⚠️ Координаты вне диапазона Башкортостана: ${coordsString}`)
        return [lat, lon] // Всё равно возвращаем, но с предупреждением
      }
    }
  } catch (e) {
    console.error('❌ Ошибка парсинга координат:', coordsString, e)
  }
  
  return null
}

// Инициализация карты
const initMap = async () => {
  if (!window.ymaps) {
    error.value = 'Не удалось загрузить API Яндекс Карт'
    return
  }

  try {
    // Создаём карту
    myMap = new window.ymaps.Map(mapContainer.value, {
      center: [54.7355, 55.9587], // Центр Башкортостана (Уфа)
      zoom: 7,
      controls: ['zoomControl', 'fullscreenControl', 'rulerControl']
    }, {
      searchControlProvider: 'yandex#search'
    })

    // Если нет колледжей, показываем сообщение
    if (colleges.value.length === 0) {
      console.warn('⚠️ Нет колледжей для отображения')
      return
    }

    // Добавляем метки для каждого адреса колледжа
    colleges.value.forEach(college => {
      college.addresses.forEach(address => {
        const coords = parseCoordinates(address.coordinates)
        if (!coords) {
          console.warn(`⚠️ Пропущен адрес без координат: ${address.address_name || address.address}`)
          return
        }

        const displayName = address.address_name || college.name
        const isMain = address.is_main

        const placemark = new window.ymaps.Placemark(coords, {
          balloonContentHeader: `<strong style="font-size:14px; color:#0054A6;">${college.name}</strong>`,
          balloonContentBody: `
            <div style="max-width:280px; padding:4px;">
              <p style="margin:6px 0; color:#333; font-size:13px;">
                <strong style="color:#0054A6;">📍 Адрес:</strong><br>
                ${address.address || 'Адрес не указан'}
              </p>
              ${address.phone ? `
                <p style="margin:6px 0; font-size:13px;">
                  <strong style="color:#0054A6;">📞 Телефон:</strong><br>
                  <a href="tel:${address.phone}" style="color:#0054A6; text-decoration:none;">${address.phone}</a>
                </p>
              ` : ''}
              ${college.city ? `
                <p style="margin:6px 0; font-size:13px;">
                  <strong style="color:#0054A6;">🏙️ Город:</strong><br>
                  ${college.city}
                </p>
              ` : ''}
              ${isMain ? '<p style="margin:6px 0; font-size:12px; color:#4CAF50;"><strong>✓ Основной адрес</strong></p>' : ''}
            </div>
          `,
          hintContent: `${college.name}${address.address_name ? ` - ${address.address_name}` : ''}`
        }, {
          preset: isMain ? 'islands#blueEducationCircleIcon' : 'islands#lightBlueCircleIcon',
          iconColor: isMain ? '#0054A6' : '#2196F3'
        })
        
        myMap.geoObjects.add(placemark)
        placemarks.push(placemark)
      })
    })

    // Автомасштабирование, если есть метки
    if (placemarks.length > 0) {
      const bounds = myMap.geoObjects.getBounds()
      if (bounds) {
        myMap.setBounds(bounds, {
          checkZoomRange: true,
          zoomMargin: 50,
          duration: 300
        })
      }
    }

    console.log('✅ Карта успешно инициализирована')
    
  } catch (err) {
    console.error('❌ Ошибка инициализации карты:', err)
    error.value = 'Ошибка при загрузке карты'
  }
}

// Очистка при размонтировании
onBeforeUnmount(() => {
  if (myMap) {
    myMap.destroy()
    myMap = null
  }
})

onMounted(async () => {
  try {
    loading.value = true
    // Загружаем API и данные
    await Promise.all([
      loadYandexMaps(),
      loadCollegesFromAPI()
    ])
    
    // Ждём, пока DOM обновится и контейнер станет видимым
    loading.value = false
    await nextTick()
    
    // Даём время для рендера контейнера
    await new Promise(resolve => setTimeout(resolve, 100))
    
    // Проверяем, что контейнер существует
    if (!mapContainer.value) {
      throw new Error('Контейнер карты не найден в DOM')
    }
    
    // Инициализируем карту
    await initMap()
  } catch (err) {
    console.error('❌ Ошибка загрузки карты:', err)
    error.value = 'Не удалось загрузить карту. Проверьте консоль для деталей.'
    loading.value = false
  }
})
</script>

<style scoped>
.map-section {
  padding: 60px 0;
  background: linear-gradient(135deg, #f5f7fa 0%, #e8eef5 100%);
}

.section-title {
  text-align: center;
  margin-bottom: 40px;
}

.section-title h2 {
  font-size: 2rem;
  color: #0054A6;
  margin-bottom: 10px;
  font-weight: 700;
}

.section-title p {
  font-size: 1.1rem;
  color: #666;
}

.loading-map,
.map-error {
  text-align: center;
  padding: 100px 20px;
  color: #666;
  font-size: 16px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.map-error {
  color: #d32f2f;
  background: #ffebee;
}

.loading-map i {
  font-size: 2.5rem;
  color: #0054A6;
  margin-bottom: 15px;
  display: block;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.map-container {
  width: 100%;
  height: 600px;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 8px 24px rgba(0, 84, 166, 0.15);
  background: white;
}

#map {
  width: 100%;
  height: 100%;
}

/* Адаптивность */
@media (max-width: 768px) {
  .map-container {
    height: 400px;
  }
  
  .section-title h2 {
    font-size: 1.5rem;
  }
  
  .section-title p {
    font-size: 1rem;
  }
}
</style>

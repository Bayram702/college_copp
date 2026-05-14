<template>
  <section class="section">
    <div class="container">
      <div class="section-title">
        <h2>Основные отрасли</h2>
        <p>Выберите направление подготовки, которое соответствует вашим интересам</p>
      </div>

      <div v-if="loading" class="loading">Загрузка отраслей...</div>

      <div v-else class="sectors-grid">
        <router-link
          v-for="sector in sectors"
          :key="sector.id"
          :to="sector.link"
          class="sector-card"
        >
          <div class="sector-content">
            <h3>{{ sector.title }}</h3>
            <p>{{ sector.description }}</p>
            <div class="sector-stats">
              <div class="stat">
                <div class="stat-value">{{ sector.colleges }}</div>
                <div class="stat-label">Колледжей</div>
              </div>
              <div class="stat">
                <div class="stat-value">{{ sector.programs }}</div>
                <div class="stat-label">Программ</div>
              </div>
            </div>
          </div>
        </router-link>
      </div>
    </div>
  </section>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { apiPath } from '../utils/api'

const sectors = ref([])
const loading = ref(true)

const loadSectors = async () => {
  try {
    const response = await fetch(apiPath('/sectors'))
    const result = await response.json()
    if (result.success) {
      sectors.value = result.data.slice(0, 9).map(sector => ({
        id: sector.id,
        title: sector.name,
        description: sector.description,
        colleges: sector.colleges_count,
        programs: sector.programs_count,
        link: { path: '/sector', query: { sector_id: String(sector.id) } }
      }))
    }
  } catch (error) {
    console.error('Ошибка загрузки секторов:', error)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadSectors()
})
</script>

<style scoped>
.loading {
  text-align: center;
  padding: 40px;
  color: #666;
  font-size: 16px;
}
</style>

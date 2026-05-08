<template>
  <section class="section professionalitet-section">
    <div class="container">
      <div class="section-title">
        <h2>Федеральный проект «Профессионалитет»</h2>
        <p>Современная образовательная программа для подготовки специалистов по наиболее востребованным профессиям</p>
      </div>
      
      <div class="professionalitet-card">              
        <p><strong>«Профессионалитет»</strong> – это федеральный проект, направленный на создание в системе СПО нового уровня образования, при котором колледжи тесно сотрудничают с предприятиями-работодателями для подготовки кадров по наиболее востребованным профессиям.</p>
        
        <div class="professionalitet-info">
          <div class="info-item" v-for="item in infoItems" :key="item.id">
            <i :class="item.icon"></i>
            <div>
              <h4>{{ item.title }}</h4>
              <p>{{ item.description }}</p>
            </div>
          </div>
        </div>
        
        <h4 style="margin-bottom: 20px; color: var(--text-dark);">Колледжи Башкортостана, участвующие в программе «Профессионалитет»:</h4>

        <div v-if="loading" class="loading">Загрузка колледжей...</div>

        <div v-else-if="colleges.length === 0" class="empty-message">
          Пока нет колледжей, участвующих в профессионалитете
        </div>

        <div v-else class="professionalitet-colleges">
          <div 
            class="college-card-prof" 
            v-for="college in colleges" 
            :key="college.id"
          >
            <img :src="college.image" :alt="college.name" class="college-image-prof">
            <div class="college-content-prof">
              <h4>{{ college.name }}</h4>
              <div class="college-tags">
                <span class="college-tag cluster">{{ college.cluster }}</span>
              </div>
            </div>
            <div class="college-footer-prof">
              <a :href="college.link" class="btn-small">Подробнее</a>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { apiPath } from '../utils/api'
import { resolveImageUrl } from '../utils/images'

const infoItems = ref([
  {
    id: 1,
    icon: 'fas fa-rocket',
    title: 'Ускоренное обучение',
    description: 'Сокращение сроков обучения до 2-3 лет за счет оптимизации программы'
  },
  {
    id: 2,
    icon: 'fas fa-handshake',
    title: 'Работодатели-партнеры',
    description: 'Непосредственное участие предприятий в разработке программ и обучении'
  },
  {
    id: 3,
    icon: 'fas fa-briefcase',
    title: 'Гарантированное трудоустройство',
    description: 'Выпускники получают работу на предприятиях-партнерах проекта'
  },
  {
    id: 4,
    icon: 'fas fa-tools',
    title: 'Современное оборудование',
    description: 'Обучение на современном оборудовании, соответствующем стандартам предприятий'
  }
])

const colleges = ref([])
const loading = ref(true)

const loadProfessionalitetColleges = async () => {
  try {
    const response = await fetch(apiPath('/colleges?professionalitet=yes&limit=20'))
    const result = await response.json()
    if (result.success) {
      colleges.value = result.data.map(c => ({
        id: c.id,
        name: c.name,
        image: resolveImageUrl(c.logo_image_url),
        cluster: c.professionalitet_cluster || 'Не указан',
        link: `/college/${c.id}`
      }))
    }
  } catch (error) {
    console.error('Ошибка загрузки колледжей профессионалитета:', error)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadProfessionalitetColleges()
})
</script>

<style scoped>
.loading, .empty-message {
  text-align: center;
  padding: 40px;
  color: #666;
  font-size: 16px;
}
</style>

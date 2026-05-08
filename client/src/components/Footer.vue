<script setup>
import { ref, onMounted } from 'vue'
import { apiPath } from '../utils/api'

const footerSettings = ref({
  address: 'г. Уфа, ул. Ленина, 1',
  phone: '+7 (347) 123-45-67',
  email: 'info@college-rb.ru'
})

const loadFooterSettings = async () => {
  try {
    const response = await fetch(apiPath('/settings'))
    const result = await response.json()
    if (result.success) {
      const data = result.data
      if (data.footer_address) footerSettings.value.address = data.footer_address.value
      if (data.footer_phone) footerSettings.value.phone = data.footer_phone.value
      if (data.footer_email) footerSettings.value.email = data.footer_email.value
    }
  } catch (error) {
    console.error('Ошибка загрузки настроек футера:', error)
    // Оставляем значения по умолчанию
  }
}

onMounted(() => {
  loadFooterSettings()
})
</script>

<template>
  <footer>
    <div class="container">
      <div class="footer-content">
        <div class="footer-column">
          <h3>Колледжи Башкортостана</h3>
          <p>Официальный портал среднего профессионального образования Республики Башкортостан.</p>
        </div>

        <div class="footer-column">
          <h3>Разделы</h3>
          <ul class="footer-links">
            <li><a href="/">Главная</a></li>
            <li><a href="/sector">Специальности</a></li>
            <li><a href="/colleges">Колледжи</a></li>
          </ul>
        </div>

        <div class="footer-column">
          <h3>Контакты</h3>
          <ul class="footer-links">
            <li><i class="fas fa-map-marker-alt"></i> {{ footerSettings.address }}</li>
            <li><i class="fas fa-phone"></i> {{ footerSettings.phone }}</li>
            <li><i class="fas fa-envelope"></i> {{ footerSettings.email }}</li>
          </ul>
        </div>
      </div>

      <div class="footer-bottom">
        <p>© {{ new Date().getFullYear() }} Колледжи Башкортостана. Все права защищены.</p>
      </div>
    </div>
  </footer>
</template>

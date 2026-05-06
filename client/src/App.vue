<template>
  <div class="app">
    <Header />

    <main>
      <RouterView />
    </main>

    <Footer />
    <BackToTop />
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { RouterView } from 'vue-router'
import axios from 'axios'
import Header from './components/Header.vue'
import Footer from './components/Footer.vue'
import BackToTop from './components/BackToTop.vue'

onMounted(() => {
  const token = localStorage.getItem('authToken')
  const userStr = localStorage.getItem('user')

  if (token && userStr) {
    try {
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`
    } catch (e) {
      localStorage.removeItem('authToken')
      localStorage.removeItem('user')
    }
  }
})
</script>

<style>
.app {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

main {
  flex: 1;
}
</style>
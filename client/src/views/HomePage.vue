<template>
  <div class="home-page">
    <HeroSection />
    <div class="flag-stripe"></div>
    <SectorsGrid />
    <ProfessionalitetSection />
    <YandexMap />
    <CtaSection />
  </div>
</template>

<script setup>
import HeroSection from '../components/HeroSection.vue'
import SectorsGrid from '../components/SectorsGrid.vue'
import ProfessionalitetSection from '../components/ProfessionalitetSection.vue'
import YandexMap from '../components/YandexMap.vue'
import CtaSection from '../components/CtaSection.vue'
</script>
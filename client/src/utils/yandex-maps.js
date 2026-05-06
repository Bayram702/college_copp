// src/utils/yandex-maps.js
export const loadYandexMaps = () => {
  return new Promise((resolve, reject) => {
    if (window.ymaps) {
      window.ymaps.ready(() => {
        resolve(window.ymaps)
      })
      return
    }

    const script = document.createElement('script')
    // Загрузка без API ключа (для разработки)
    script.src = 'https://api-maps.yandex.ru/2.1/?lang=ru_RU'
    script.type = 'text/javascript'
    script.onload = () => {
      window.ymaps.ready(() => {
        resolve(window.ymaps)
      })
    }
    script.onerror = (e) => {
      console.error('Ошибка загрузки Yandex Maps API:', e)
      reject(e)
    }
    document.head.appendChild(script)
  })
}
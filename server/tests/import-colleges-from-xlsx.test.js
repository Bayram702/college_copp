const assert = require('node:assert/strict')
const path = require('node:path')
const test = require('node:test')

const { loadCollegesFromXlsx } = require('../scripts/import-colleges-from-xlsx')

test('loads college rows from the source XLSX', () => {
  const rows = loadCollegesFromXlsx(path.resolve('C:/Users/pl/Desktop/колледжи.xlsx'))

  assert.equal(rows.length, 99)
  assert.deepEqual(rows[0], {
    name: 'ГБПОУ Аксеновский агропромышленный колледж',
    shortName: 'ААПК',
    email: 'acxt@mail.ru',
    phone: '8 (347) 543-60-47',
    website: 'https://acxt.ru/',
    socialVk: 'https://vk.com/aapk_acxt?ysclid=m6hib3zca2607959828',
    isProfessionalitet: false,
    admissionLink: 'https://acxt.ru/%d0%b0%d0%b1%d0%b8%d1%82%d1%83%d1%80%d0%b8%d0%b5%d0%bd%d1%82%d1%83/'
  })

  assert.equal(rows[1].name, 'ГБПОУ Акъярский горный колледж имени И.Тасимова')
  assert.equal(rows[1].isProfessionalitet, true)
  assert.equal(rows.at(-1).name, 'Бирский филиал СПО УУНиТ')
})

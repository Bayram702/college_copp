import { expect, test } from '@playwright/test'

const apiBase = 'http://127.0.0.1:3000/api'

async function expectNoPageErrors(page, action) {
  const errors = []
  page.on('pageerror', error => errors.push(error.message))
  page.on('console', message => {
    const text = message.text()
    if (message.type() === 'error' && !text.includes('net::ERR_NETWORK_ACCESS_DENIED')) errors.push(text)
  })
  await action()
  expect(errors, errors.join('\n')).toEqual([])
}

async function login(page, username, password) {
  await page.goto('/login')
  await page.locator('#username').fill(username)
  await page.locator('#password').fill(password)
  await page.locator('button[type="submit"]').click()
}

async function selectFirstSector(page) {
  const firstSector = page.locator('.sector-filter-card').nth(1)
  await expect(firstSector).toBeVisible()
  await firstSector.evaluate(element => element.click())
  await expect(page.locator('.sector-filter-card.active')).toHaveCount(1)
}

test.describe('public pages', () => {
  test('home page opens without console errors', async ({ page }) => {
    await expectNoPageErrors(page, async () => {
      await page.goto('/')
      await expect(page.locator('body')).toContainText('Колледжи')
      await expect(page.getByRole('heading', { name: 'Подача документов' })).toBeVisible()
      await expect(page.locator('body')).not.toContainText('Готовы выбрать свою профессию?')
    })
  })

  test('colleges page supports breadcrumbs, sector filter, search and pagination', async ({ page }) => {
    await expectNoPageErrors(page, async () => {
      await page.goto('/colleges')
      await expect(page.locator('.breadcrumbs')).toContainText('Главная')
      await expect(page.locator('.breadcrumbs')).toContainText('Колледжи')
      await expect(page.locator('.catalog-search .search-input')).toBeVisible()
      await expect(page.locator('.catalog-search .search-input')).toHaveCSS('width', /.+/)

      await selectFirstSector(page)

      await page.getByRole('button', { name: 'Сбросить' }).click()
      await page.locator('.catalog-search .search-input').fill('Уф')
      await page.getByRole('button', { name: 'Найти' }).click()
      await expect(page.locator('.college-card').first()).toBeVisible()

      const pageButtons = page.locator('.pagination-btn')
      if (await pageButtons.count() > 2) {
        await pageButtons.last().click()
        await expect(page.locator('.college-card').first()).toBeVisible()
      }
    })
  })

  test('specialties page supports breadcrumbs, sector filter, search and pagination', async ({ page }) => {
    await expectNoPageErrors(page, async () => {
      await page.goto('/sector')
      await expect(page.locator('.breadcrumbs')).toContainText('Главная')
      await expect(page.locator('.breadcrumbs')).toContainText('Специальности')
      await expect(page.locator('.catalog-search .search-input')).toBeVisible()
      await expect(page.locator('text=Все специальности СПО')).toHaveCount(0)

      await selectFirstSector(page)

      await page.getByRole('button', { name: 'Сбросить' }).click()
      await page.locator('.catalog-search .search-input').fill('тех')
      await page.getByRole('button', { name: 'Найти' }).click()
      await expect(page.locator('.specialty-card').first()).toBeVisible()
      await expect(page.locator('text=Трудоустройство выпускников')).toHaveCount(0)

      const pageButtons = page.locator('.pagination-btn')
      if (await pageButtons.count() > 2) {
        await pageButtons.last().click()
        await expect(page.locator('.specialty-card').first()).toBeVisible()
      }
    })
  })

  test('detail pages open from cards and show breadcrumbs', async ({ page }) => {
    await page.goto('/colleges')
    await page.locator('.college-card .btn-details').first().click()
    await expect(page.locator('.breadcrumbs')).toContainText('Главная')
    await expect(page.locator('.breadcrumbs')).toContainText('Колледжи')
    await expect(page.locator('h1')).toBeVisible()

    await page.goto('/sector')
    await page.locator('.specialty-card .specialty-details-btn').first().click()
    await expect(page.locator('.breadcrumbs')).toContainText('Главная')
    await expect(page.locator('.breadcrumbs')).toContainText('Специальности')
    await expect(page.locator('h1')).toBeVisible()
    await expect(page.locator('body')).toContainText(/Колледжи|не найден/)
  })
})

test.describe('api smoke tests', () => {
  test('core api endpoints respond successfully', async ({ request }) => {
    const endpoints = [
      `${apiBase}/sectors`,
      `${apiBase}/specialties?limit=3&page=1`,
      `${apiBase}/specialties?sector_id=1&limit=3&page=1`,
      `${apiBase}/colleges?limit=3&page=1`,
      `${apiBase}/colleges?sector_id=1&limit=3&page=1`,
      `${apiBase}/colleges/stats`
    ]

    for (const endpoint of endpoints) {
      const response = await request.get(endpoint)
      expect(response.ok(), endpoint).toBeTruthy()
      const body = await response.json()
      expect(body.success, endpoint).toBeTruthy()
    }
  })

  test('removed applicant registration endpoint is unavailable', async ({ request }) => {
    const response = await request.post(`${apiBase}/auth/register-applicant`, {
      data: { name: 'Test', login: 'test-applicant', email: 'test@example.com', password: '123456' }
    })
    expect([404, 405]).toContain(response.status())
  })

  test('representative validation rejects unsupported roles and invalid fields', async ({ request }) => {
    const login = await request.post(`${apiBase}/auth/login`, {
      data: { username: 'admin', password: 'admin123' }
    })
    expect(login.ok()).toBeTruthy()
    const { data } = await login.json()

    const response = await request.post(`${apiBase}/users`, {
      headers: { Authorization: `Bearer ${data.token}` },
      data: {
        name: 'A',
        login: 'bad login',
        email: 'bad-email',
        phone: '+7 999',
        password: '123',
        role: 'applicant',
        status: 'active',
        college_id: ''
      }
    })
    expect(response.status()).toBe(400)
    const body = await response.json()
    expect(body.success).toBeFalsy()
    expect(body.errors).toBeTruthy()
  })
})

test.describe('auth pages', () => {
  test('admin can log in and open admin panel', async ({ page }) => {
    await login(page, 'admin', 'admin123')
    await expect(page).toHaveURL(/\/admin/)
    await expect(page.locator('.breadcrumbs')).toContainText('Панель администратора')
    await expect(page.locator('.tabs')).toBeVisible()
  })

  test('bad password shows login error', async ({ page }) => {
    await login(page, 'admin', 'wrong-password')
    await expect(page.locator('.error-message')).toBeVisible()
    await expect(page.locator('button[type="submit"]')).toBeEnabled()

    await page.locator('#password').fill('wrong-password')
    await page.locator('button[type="submit"]').click()
    await expect(page.locator('.error-message')).toBeVisible()
    await expect(page.locator('body')).not.toContainText('Слишком много попыток входа')
  })
})

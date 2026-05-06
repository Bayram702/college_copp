import { expect, test } from '@playwright/test'

const pages = ['/', '/sector', '/colleges']

test.describe('mobile layout', () => {
  test('header menu opens on mobile', async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 })
    await page.goto('/')

    const menuButton = page.locator('.mobile-menu-btn')
    await expect(menuButton).toBeVisible()
    await menuButton.click()
    await expect(page.locator('.nav-menu.open')).toBeVisible()
    await expect(page.locator('.nav-menu.open a').first()).toBeVisible()
  })

  for (const path of pages) {
    test(`page ${path} fits mobile viewport`, async ({ page }) => {
      await page.setViewportSize({ width: 390, height: 844 })
      await page.goto(path)
      await page.waitForLoadState('networkidle')

      const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth)
      expect(overflow).toBeLessThanOrEqual(2)
    })
  }
})

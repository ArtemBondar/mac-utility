const { test, expect } = require('@playwright/test');

for (const language of ['en', 'uk']) {
  test(`renders ${language} without horizontal overflow and keeps download links usable`, async ({ page }) => {
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    await page.goto('/');
    await page.locator(`[data-lang="${language}"]`).click();
    await expect(page.locator('html')).toHaveAttribute('lang', language);
    await expect(page).toHaveTitle(/Clicklet/);
    await expect(page.locator('.brand')).toHaveText('Clicklet');
    await expect(page.locator(`[data-lang="${language}"]`)).toHaveAttribute('aria-pressed', 'true');
    await expect(page.locator('h1')).toContainText(language === 'en' ? 'Small actions.' : 'Маленькі дії.');
    await expect(page.locator('h1 .hero-period')).toHaveCount(1);
    await expect(page.locator('h1 .hero-period')).toHaveText('.');
    await expect(page.locator('h1 .hero-period')).toHaveCSS('color', 'rgb(199, 120, 94)');
    await expect(page.locator('.action-list article')).toHaveCount(4);
    for (const download of await page.locator('[data-i18n="download"]').all()) {
      await expect(download).toHaveAttribute('href', 'https://github.com/ArtemBondar/mac-utility/releases/download/v1.0.2/Clicklet-1.0.2.zip');
      await expect(download).toBeVisible();
    }
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
    // Section labels should sit above their content, rather than reserving an
    // empty desktop rail. Verify the real geometry in both languages/viewports.
    for (const id of ['what', 'why', 'how']) {
      const label = await page.locator(`#${id} .eyebrow`).boundingBox();
      const heading = await page.locator(`#${id} h2`).boundingBox();
      expect(Math.abs(label.x - heading.x)).toBeLessThan(2);
      expect(heading.y - label.y - label.height).toBeLessThanOrEqual(16);
      expect(heading.y).toBeGreaterThanOrEqual(label.y + label.height);
    }
    const steps = await page.locator('.steps li').all();
    const firstStep = await steps[0].boundingBox();
    const secondStep = await steps[1].boundingBox();
    if (page.viewportSize().width > 740) {
      expect(Math.abs(firstStep.y - secondStep.y)).toBeLessThan(2);
    } else {
      expect(secondStep.y).toBeGreaterThan(firstStep.y + firstStep.height);
    }
    expect(errors).toEqual([]);
    await page.reload();
    await expect(page.locator('html')).toHaveAttribute('lang', language);
    await expect(page.locator('h1')).toContainText(language === 'en' ? 'Small actions.' : 'Маленькі дії.');
  });
}

test('theme changes persist and the system choice follows the OS', async ({ page }) => {
  await page.emulateMedia({ colorScheme: 'light' });
  await page.goto('/');
  await expect(page.locator('.theme')).toHaveText('Theme: System');
  await expect(page.locator('html')).not.toHaveAttribute('data-theme');
  const light = await page.locator('body').evaluate(element => getComputedStyle(element).backgroundColor);
  await page.locator('.theme').click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  const dark = await page.locator('body').evaluate(element => getComputedStyle(element).backgroundColor);
  expect(dark).not.toBe(light);
  await page.reload();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  await page.locator('.theme').click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
  await page.locator('.theme').click();
  await expect(page.locator('html')).not.toHaveAttribute('data-theme');
  await page.emulateMedia({ colorScheme: 'dark' });
  await expect.poll(() => page.locator('body').evaluate(element => getComputedStyle(element).backgroundColor)).toBe(dark);
});

test('keyboard navigation reveals the skip link and reaches the main content', async ({ page }) => {
  await page.goto('/');
  await page.keyboard.press('Tab');
  await expect(page.getByRole('link', { name: 'Skip to content' })).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(page).toHaveURL(/#main$/);
});

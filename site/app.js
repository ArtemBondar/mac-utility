(function (global) {
  'use strict';
  const supportedLanguages = ['en', 'uk'];
  function chooseLanguage(saved, browser) {
    return supportedLanguages.includes(saved) ? saved : /^uk(?:-|$)/i.test(browser || '') ? 'uk' : 'en';
  }
  function nextTheme(current) {
    return current === 'dark' ? 'light' : current === 'light' ? null : 'dark';
  }
  function applyTranslations(doc, language, strings) {
    doc.documentElement.lang = language;
    doc.querySelectorAll('[data-i18n]').forEach(node => {
      const key = node.getAttribute('data-i18n');
      if (Object.prototype.hasOwnProperty.call(strings, key)) {
        const value = strings[key];
        node.textContent = value;
        if (key === 'hero.title' && value.endsWith('.')) {
          node.textContent = value.slice(0, -1);
          const period = doc.createElement('span');
          period.className = 'hero-period';
          period.textContent = '.';
          node.append(period);
        }
      }
    });
    doc.querySelectorAll('[data-i18n-aria]').forEach(node => {
      const key = node.getAttribute('data-i18n-aria');
      if (Object.prototype.hasOwnProperty.call(strings, key)) node.setAttribute('aria-label', strings[key]);
    });
    doc.querySelectorAll('[data-lang]').forEach(node => node.setAttribute('aria-pressed', String(node.getAttribute('data-lang') === language)));
    doc.title = strings['page.title'];
    doc.querySelector('meta[name="description"]').setAttribute('content', strings['page.description']);
  }
  function save(storage, key, value) {
    try { value === null ? storage.removeItem(key) : storage.setItem(key, value); } catch (_) {}
  }
  function read(storage, key) { try { return storage.getItem(key); } catch (_) { return null; } }
  const api = {chooseLanguage, nextTheme, applyTranslations, save, read};
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  if (!global.document) return;
  const doc = global.document;
  const themeButton = doc.querySelector('.theme');
  let storage;
  try { storage = global.localStorage; } catch (_) {}
  let language = chooseLanguage(read(storage, 'macutility-language'), global.navigator.language);
  let languageRequest = 0;
  let strings;
  function updateThemeLabel() {
    if (!strings) return;
    themeButton.textContent = strings['theme.' + (doc.documentElement.dataset.theme || 'system')];
  }
  themeButton.addEventListener('click', () => {
    const theme = nextTheme(doc.documentElement.dataset.theme);
    if (theme) doc.documentElement.dataset.theme = theme;
    else delete doc.documentElement.dataset.theme;
    save(storage, 'theme', theme);
    updateThemeLabel();
  });
  async function setLanguage(next) {
    // Only known filenames can be loaded; translated strings are inserted as text.
    if (!supportedLanguages.includes(next)) return;
    const request = ++languageRequest;
    try {
      const response = await fetch('locales/' + next + '.json');
      if (!response.ok) throw new Error('Translation unavailable');
      const translated = await response.json();
      if (request !== languageRequest) return;
      language = next;
      strings = translated;
      applyTranslations(doc, language, strings);
      updateThemeLabel();
      save(storage, 'macutility-language', language);
    } catch (_) {
      // English HTML remains usable if a translation request cannot be served.
    }
  }
  doc.querySelectorAll('[data-lang]').forEach(button => button.addEventListener('click', () => setLanguage(button.getAttribute('data-lang'))));
  setLanguage(language);
})(typeof window === 'undefined' ? globalThis : window);

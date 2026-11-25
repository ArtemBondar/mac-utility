"""Static publishing and translated interaction checks for the app website."""
from html.parser import HTMLParser
import json
import re
from pathlib import Path
import subprocess
import unittest
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / 'site'


class Page(HTMLParser):
    def __init__(self, source):
        super().__init__()
        self.elements = []
        self.feed(source)

    def handle_starttag(self, tag, attrs):
        self.elements.append((tag, dict(attrs)))


class SiteTests(unittest.TestCase):
    def setUp(self):
        self.page = Page((SITE / 'index.html').read_text())
        self.en = json.loads((SITE / 'locales/en.json').read_text())
        self.uk = json.loads((SITE / 'locales/uk.json').read_text())

    def test_translation_coverage_and_actions(self):
        self.assertEqual(self.en.keys(), self.uk.keys())
        used = {attrs[key] for _, attrs in self.page.elements for key in ['data-i18n', 'data-i18n-aria'] if key in attrs}
        self.assertTrue(used <= self.en.keys(), used - self.en.keys())
        self.assertTrue(all(value.strip() for value in self.en.values()))
        self.assertTrue(all(value.strip() for value in self.uk.values()))
        for key in ['action.file', 'action.folder', 'action.terminal', 'action.path']:
            self.assertIn(key, used)
        self.assertEqual({'en', 'uk'}, {attrs['data-lang'] for _, attrs in self.page.elements if 'data-lang' in attrs})

    def test_assets_navigation_and_release_download(self):
        ids = [attrs['id'] for _, attrs in self.page.elements if 'id' in attrs]
        self.assertEqual(len(ids), len(set(ids)))
        for tag, attrs in self.page.elements:
            for attribute in ['src', 'href']:
                value = attrs.get(attribute)
                if not value:
                    continue
                if value.startswith('#'):
                    self.assertIn(value[1:], ids)
                elif not urlparse(value).scheme:
                    self.assertTrue((SITE / value).is_file(), value)
            if tag == 'img':
                self.assertIn('alt', attrs)
        downloads = [attrs['href'] for _, attrs in self.page.elements if attrs.get('data-i18n') == 'download']
        self.assertEqual(len(downloads), 2)
        self.assertEqual(set(downloads), {'https://github.com/ArtemBondar/mac-utility/releases/download/v1.0.0/MacUtility-1.0.0.zip'})
        self.assertIn('not notarized', self.en['signing'])
        self.assertIn('Apple silicon', self.en['hero.note'])

    def test_no_external_runtime_dependency(self):
        scripts = [attrs.get('src') for tag, attrs in self.page.elements if tag == 'script']
        self.assertTrue(scripts)
        self.assertTrue(all(source and not urlparse(source).scheme for source in scripts))
        self.assertTrue((SITE / '.nojekyll').exists())

    def test_pages_deployment_uses_scoped_permissions_and_pinned_actions(self):
        workflow = (ROOT / '.github/workflows/pages.yml').read_text()
        self.assertIn('branches: [develop]', workflow)
        self.assertIn("github.event_name != 'pull_request' && github.ref == 'refs/heads/develop'", workflow)
        self.assertIn('contents: read', workflow)
        self.assertIn('pages: write', workflow)
        self.assertIn('id-token: write', workflow)
        self.assertNotIn('pull_request_target', workflow)
        self.assertNotIn('contents: write', workflow)
        self.assertIn('path: site', workflow)
        actions = re.findall(r'uses: ([^\s]+)', workflow)
        self.assertTrue(actions)
        self.assertTrue(all(re.fullmatch(r'actions/[a-z-]+@[a-f0-9]{40}', action) for action in actions))

    def test_language_and_theme_interactions(self):
        subprocess.run(['node', str(ROOT / 'Tests/site_interaction.test.js')], cwd=ROOT, check=True, capture_output=True, text=True)


if __name__ == '__main__':
    unittest.main()

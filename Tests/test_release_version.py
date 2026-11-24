import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('verify_release_version', Path(__file__).parents[1] / 'scripts/verify_release_version.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ReleaseVersionTests(unittest.TestCase):
    def prepare(self, root, versions=None):
        (root / 'MacUtility.xcodeproj').mkdir()
        values = versions or ['1.0.0'] * 6
        (root / 'MacUtility.xcodeproj/project.pbxproj').write_text('\n'.join('MARKETING_VERSION = ' + value + ';' for value in values))
        (root / 'docs/releases').mkdir(parents=True)
        (root / 'docs/releases/v1.0.0.md').write_text('Initial release.')

    def test_matching_release_is_accepted(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.prepare(root)
            module.verify('v1.0.0', root)

    def test_mismatched_extension_version_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.prepare(root, ['1.0.0'] * 5 + ['0.1.0'])
            with self.assertRaisesRegex(ValueError, 'all app and extension'):
                module.verify('v1.0.0', root)

    def test_missing_notes_are_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.prepare(root)
            (root / 'docs/releases/v1.0.0.md').unlink()
            with self.assertRaisesRegex(ValueError, 'Release notes'):
                module.verify('v1.0.0', root)

    def test_invalid_version_is_rejected(self):
        for tag in ['1.0.0', 'v01.0.0', 'v1.0.0/other', 'v1.0.0\nextra']:
            with self.assertRaises(ValueError):
                module.verify(tag, Path('/unused'))

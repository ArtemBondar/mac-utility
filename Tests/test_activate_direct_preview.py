import importlib.util
from pathlib import Path
import unittest
import plistlib
import tempfile

spec = importlib.util.spec_from_file_location('activate_direct_preview', Path(__file__).parents[1] / 'scripts/activate_direct_preview.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class DirectPreviewActivationTests(unittest.TestCase):
    def test_only_exact_direct_extension_is_selected(self):
        output = '+    com.example.MacUtilityDirect.FinderExtension(0.1.0)\tuuid\tdate\t/Users/test/old app/MacUtility.app/Contents/PlugIns/FinderExtension.appex\n'
        output += '+    com.example.MacUtility.FinderExtension(0.1.0)\tuuid\tdate\t/Users/test/store.app/Contents/PlugIns/FinderExtension.appex\n'
        output += '+    com.example.MacUtilityDirect.FinderExtensionOther(0.1.0)\tuuid\tdate\t/tmp/other.appex\n'
        self.assertEqual(module.registered_paths(output), [Path('/Users/test/old app/MacUtility.app/Contents/PlugIns/FinderExtension.appex')])

    def test_only_exact_executable_matches(self):
        executable = Path('/tmp/old app/MacUtility.app/Contents/MacOS/MacUtility')
        output = '42 ' + str(executable) + ' -argument\n43 /tmp/unrelated\n44 ' + str(executable) + 'Other\n'
        self.assertEqual(module.executable_pids(output, [executable]), [42])

    def test_invalid_app_is_rejected(self):
        with self.assertRaises(FileNotFoundError):
            module.validate_app('/does/not/exist.app')

    def test_sandboxed_app_identifier_is_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            app = Path(root) / 'MacUtility.app'
            (app / 'Contents').mkdir(parents=True)
            with (app / 'Contents/Info.plist').open('wb') as stream:
                plistlib.dump({'CFBundleIdentifier': 'com.example.MacUtility'}, stream)
            with self.assertRaises(ValueError):
                module.validate_app(app)

    def test_renamed_bundle_preserves_existing_direct_identity(self):
        with tempfile.TemporaryDirectory() as root:
            app = Path(root) / 'Clicklet.app'
            extension = app / 'Contents/PlugIns/FinderExtension.appex'
            for bundle, identifier in [(app, module.HOST_ID), (extension, module.EXTENSION_ID)]:
                (bundle / 'Contents').mkdir(parents=True)
                with (bundle / 'Contents/Info.plist').open('wb') as stream:
                    plistlib.dump({'CFBundleIdentifier': identifier, 'CFBundleDisplayName': 'Clicklet'}, stream)
            self.assertEqual(module.validate_app(app), (app.resolve(), extension.resolve()))

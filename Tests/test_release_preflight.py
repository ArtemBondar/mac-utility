import importlib.util
import contextlib
import io
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

path = Path(__file__).resolve().parents[1] / 'scripts/release_preflight.py'
spec = importlib.util.spec_from_file_location('release_preflight', path)
preflight = importlib.util.module_from_spec(spec)
spec.loader.exec_module(preflight)


class DeveloperIdentityTests(unittest.TestCase):
    def test_accepts_valid_developer_id_application_identity(self):
        self.assertTrue(preflight.has_developer_id('  1) ABCDEF1234 "Developer ID Application: Example (TEAMID)"'))

    def test_rejects_adhoc_apple_development_and_zero_identities(self):
        self.assertFalse(preflight.has_developer_id('  1) ABCDEF1234 "Apple Development: Example"\n  0 valid identities found'))

    def test_rejects_invalid_identity(self):
        self.assertFalse(preflight.has_developer_id('  1) ABCDEF1234 "Developer ID Application: Example" (CSSMERR_TP_CERT_EXPIRED)'))

    @patch.object(preflight.subprocess, 'run')
    @patch('pathlib.Path.read_text')
    def test_reports_blockers(self, read_text, run):
        read_text.return_value = 'PRODUCT_BUNDLE_IDENTIFIER = com.example.MacUtility;'
        run.return_value.stdout = '0 valid identities found'
        with contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertEqual(preflight.main(), 1)
        self.assertIn('placeholder bundle identifier', output.getvalue())
        self.assertIn('Developer ID Application', output.getvalue())

    @patch.object(preflight.subprocess, 'run')
    @patch('pathlib.Path.read_text')
    def test_command_failure_is_not_success(self, read_text, run):
        read_text.return_value = 'PRODUCT_BUNDLE_IDENTIFIER = org.example.custom;'
        run.side_effect = subprocess.CalledProcessError(1, 'security')
        with contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(preflight.main(), 2)


if __name__ == '__main__':
    unittest.main()

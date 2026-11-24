"""Regression checks for workflow safety and preview packaging behavior."""
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class PipelineTests(unittest.TestCase):
    def test_workflow_triggers_and_permissions(self):
        ci = (ROOT / '.github/workflows/ci.yml').read_text()
        release = (ROOT / '.github/workflows/release.yml').read_text()
        self.assertIn('pull_request:', ci)
        self.assertIn('branches: [main, develop]', ci)
        self.assertIn('branches: [develop]', ci)
        self.assertIn("tags: ['v*']", release)
        self.assertIn('workflow_dispatch:', release)
        self.assertIn('Manual releases must run from main', release)
        self.assertIn('--verify-tag', release)
        self.assertNotIn('--verify-tag --draft', release)
        self.assertIn('build-direct-preview.sh', release)
        self.assertIn('verify_release_version.py', release)
        self.assertIn('Existing release tag points to a different commit', release)
        self.assertIn('--target "$GITHUB_SHA"', release)
        self.assertIn('--notes-file "$notes"', release)
        self.assertNotIn('--clobber', release)
        self.assertIn('git merge-base --is-ancestor "$GITHUB_SHA" refs/remotes/origin/main', release)
        self.assertNotIn('git merge-base --is-ancestor "$GITHUB_SHA" refs/remotes/origin/develop', release)
        self.assertIn('fetch-depth: 0', release)
        self.assertIn('Only develop can be promoted to main', ci)
        self.assertIn('"$HEAD_REPOSITORY" == "$BASE_REPOSITORY"', ci)
        self.assertIn('not notarized', (ROOT / 'docs/releases/v1.0.0.md').read_text())
        self.assertNotIn('pull_request_target:', ci + release)
        self.assertIn('contents: read', ci)
        self.assertIn('contents: write', release)
        self.assertIn('persist-credentials: false', ci)
        self.assertIn('persist-credentials: false', release)

    def test_preview_build_packages_signed_bundles(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            binaries = tmp / 'bin'
            binaries.mkdir()
            trace = tmp / 'trace'
            stubs = {
                'xcodebuild': '''#!/bin/bash
set -eu
while [[ "$1" != "-derivedDataPath" ]]; do shift; done
mkdir -p "$2/Build/Products/Release/MacUtility.app/Contents/PlugIns/FinderExtension.appex"
''',
                'codesign': '#!/bin/bash\nprintf "%s\\n" "$*" >> "$TRACE"\n',
                'ditto': '#!/bin/bash\nprintf preview > "${@: -1}"\n',
            }
            for name, contents in stubs.items():
                target = binaries / name
                target.write_text(contents)
                target.chmod(0o755)
            env = {**os.environ, 'PATH': f'{binaries}:{os.environ["PATH"]}', 'TRACE': str(trace)}
            out = tmp / 'result'
            command = ['bash', str(ROOT / 'scripts/build-preview.sh'), str(out)]
            subprocess.run(command, env=env, check=True, capture_output=True, text=True)
            self.assertEqual((out / 'MacUtility-preview.zip').read_text(), 'preview')
            log = trace.read_text()
            self.assertIn('FinderExtension.entitlements', log)
            self.assertIn('MacUtility.entitlements', log)
            self.assertIn('--verify --strict --deep', log)
            second = subprocess.run(command, env=env, capture_output=True, text=True)
            self.assertEqual(second.returncode, 2)
            self.assertEqual((out / 'MacUtility-preview.zip').read_text(), 'preview')


if __name__ == '__main__':
    unittest.main()

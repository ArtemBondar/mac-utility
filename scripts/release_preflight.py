#!/usr/bin/env python3
"""Read-only checks for direct-download release prerequisites (not certification)."""
import re
import subprocess
import sys
from pathlib import Path


def has_developer_id(output: str) -> bool:
    # Only numbered, valid codesigning identities count; exclude revoked/expired rows.
    return any(re.match(r'^\s*\d+\)\s+[A-Fa-f0-9]+\s+"Developer ID Application:', line)
               and 'CSSMERR' not in line for line in output.splitlines())


def main() -> int:
    project = Path(__file__).resolve().parents[1] / 'MacUtility.xcodeproj/project.pbxproj'
    try:
        settings = project.read_text(encoding='utf-8')
        result = subprocess.run(['security', 'find-identity', '-v', '-p', 'codesigning'],
                                capture_output=True, text=True, check=True)
    except (OSError, subprocess.CalledProcessError) as error:
        print(f'Unable to inspect release prerequisites: {error}', file=sys.stderr)
        return 2
    blockers = []
    if 'PRODUCT_BUNDLE_IDENTIFIER = com.example.MacUtility;' in settings:
        blockers.append('Replace the placeholder bundle identifier with one you control.')
    if not has_developer_id(result.stdout):
        blockers.append('Install a valid Developer ID Application signing identity.')
    for blocker in blockers:
        print(f'BLOCKED: {blocker}')
    print('Manual verification required: production Finder integration, folder permissions, '
          'release signature, notarization, stapling, and clean-account installation.')
    print('These checks do not determine App Store eligibility or certify a release.')
    return 1 if blockers else 0


if __name__ == '__main__':
    sys.exit(main())

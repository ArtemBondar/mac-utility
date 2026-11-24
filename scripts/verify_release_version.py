#!/usr/bin/env python3
"""Reject release tags that do not match the app or lack release notes."""
from pathlib import Path
import re
import sys


def verify(tag, root):
    if not re.fullmatch(r'v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)', tag):
        raise ValueError('Expected a version tag such as v1.0.0')
    project = (root / 'MacUtility.xcodeproj/project.pbxproj').read_text()
    versions = re.findall(r'MARKETING_VERSION\s*=\s*([^;]+);', project)
    if len(versions) != 6 or any(version.strip() != tag[1:] for version in versions):
        raise ValueError('Release tag must match all app and extension versions')
    notes = root / 'docs/releases' / (tag + '.md')
    if not notes.is_file() or not notes.read_text().strip():
        raise ValueError('Release notes are required for ' + tag)


if __name__ == '__main__':
    try:
        if len(sys.argv) != 2:
            raise ValueError('Usage: verify_release_version.py v1.0.0')
        verify(sys.argv[1], Path(__file__).resolve().parents[1])
    except (ValueError, OSError) as error:
        sys.exit(str(error))

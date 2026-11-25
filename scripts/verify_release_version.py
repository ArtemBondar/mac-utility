#!/usr/bin/env python3
"""Reject release tags that do not match the app or lack release notes."""
from pathlib import Path
import re
import sys


def project_version(root):
    project = (root / 'MacUtility.xcodeproj/project.pbxproj').read_text()
    versions = [value.strip() for value in re.findall(r'MARKETING_VERSION\s*=\s*([^;]+);', project)]
    if len(versions) != 6 or len(set(versions)) != 1:
        raise ValueError('Release tag must match all app and extension versions')
    version = versions[0]
    if not re.fullmatch(r'(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)', version):
        raise ValueError('Expected a project version such as 1.0.0')
    return version


def verify(tag, root):
    if not re.fullmatch(r'v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)', tag):
        raise ValueError('Expected a version tag such as v1.0.0')
    if project_version(root) != tag[1:]:
        raise ValueError('Release tag must match all app and extension versions')
    notes = root / 'docs/releases' / (tag + '.md')
    if not notes.is_file() or not notes.read_text().strip():
        raise ValueError('Release notes are required for ' + tag)


if __name__ == '__main__':
    try:
        if len(sys.argv) != 2:
            raise ValueError('Usage: verify_release_version.py v1.0.0')
        root = Path(__file__).resolve().parents[1]
        if sys.argv[1] == '--current':
            print(project_version(root))
        else:
            verify(sys.argv[1], root)
    except (ValueError, OSError) as error:
        sys.exit(str(error))

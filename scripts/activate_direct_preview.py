#!/usr/bin/env python3
"""Select one locally built Direct preview without deleting old app copies."""
import argparse
import os
from pathlib import Path
import plistlib
import re
import signal
import subprocess

HOST_ID = 'com.example.MacUtilityDirect'
EXTENSION_ID = HOST_ID + '.FinderExtension'
LSREGISTER = '/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister'


def registered_paths(output):
    paths = []
    for line in output.splitlines():
        if not re.match(r'^\s*[+!-]?\s*' + re.escape(EXTENSION_ID) + r'\(', line):
            continue
        fields = line.split('\t')
        if len(fields) >= 2 and fields[-1].endswith('.appex'):
            paths.append(Path(fields[-1]))
    return paths


def executable_pids(output, executables):
    result = []
    for line in output.splitlines():
        parts = line.strip().split(None, 1)
        if len(parts) != 2 or not parts[0].isdigit():
            continue
        if any(parts[1] == str(path) or parts[1].startswith(str(path) + ' ') for path in executables):
            result.append(int(parts[0]))
    return result


def validate_app(path):
    app = Path(path).resolve()
    extension = app / 'Contents/PlugIns/FinderExtension.appex'
    for bundle, identifier in [(app, HOST_ID), (extension, EXTENSION_ID)]:
        with (bundle / 'Contents/Info.plist').open('rb') as stream:
            info = plistlib.load(stream)
        if info.get('CFBundleIdentifier') != identifier:
            raise ValueError('Expected a Mac Utility Direct preview: ' + str(bundle))
    return app, extension


def activate(path):
    app, extension = validate_app(path)
    subprocess.run(['codesign', '--verify', '--strict', '--deep', str(app)], check=True)
    query = subprocess.run(['pluginkit', '-m', '-A', '-D', '-v', '-i', EXTENSION_ID], capture_output=True, text=True, check=True)
    stale = [path for path in registered_paths(query.stdout) if path != extension]
    executables = []
    for old in stale:
        # Only a conventional containing Direct app is eligible for unregistering.
        host = old.parent.parent.parent
        try:
            with (host / 'Contents/Info.plist').open('rb') as stream:
                info = plistlib.load(stream)
        except (OSError, plistlib.InvalidFileException):
            continue
        if info.get('CFBundleIdentifier') != HOST_ID:
            continue
        subprocess.run(['pluginkit', '-r', str(old)], check=True)
        subprocess.run([LSREGISTER, '-u', str(host)], check=True)
        executables.extend([old / 'Contents/MacOS/FinderExtension', host / 'Contents/MacOS/MacUtility'])
    processes = subprocess.run(['ps', '-axo', 'pid=,command='], capture_output=True, text=True, check=True)
    for pid in executable_pids(processes.stdout, executables):
        try:
            os.kill(pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
    subprocess.run([LSREGISTER, '-f', str(app)], check=True)
    subprocess.run(['pluginkit', '-a', str(extension)], check=True)
    print('Selected Direct preview: ' + str(app))
    print('No files were deleted and no extension enablement or privacy permissions were changed.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', help='Path to the Direct MacUtility.app to use')
    activate(parser.parse_args().app)

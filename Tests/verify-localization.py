#!/usr/bin/env python3
"""Validate translation coverage, placeholders and localization calls."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
resource = root / 'Sources/MacUtility/Resources'

def read_strings(language):
    result = {}
    pattern = re.compile(r'^\s*("(?:[^"\\]|\\.)*")\s*=\s*("(?:[^"\\]|\\.)*");\s*$')
    for line in (resource / f'{language}.lproj/Localizable.strings').read_text(encoding='utf-8').splitlines():
        m = pattern.fullmatch(line)
        assert m, f'{language}: invalid strings entry: {line}'
        key, value = map(json.loads, m.groups())
        assert key not in result and value, f'{language}: duplicate or empty translation: {key}'
        result[key] = value
    return result

en, uk = read_strings('en'), read_strings('uk')
assert en.keys() == uk.keys(), f'keys differ: {en.keys() ^ uk.keys()}'
for key in en:
    assert en[key] == key, f'English fallback must match key: {key}'
    for table in (en, uk):
        assert re.findall(r'%(?:\d+\$)?[@dfis]', table[key]) == re.findall(r'%(?:\d+\$)?[@dfis]', key), f'placeholder mismatch: {key}'
source = '\n'.join(p.read_text() for p in (root / 'Sources/MacUtility').glob('*.swift'))
used = set(re.findall(r'L10n\.(?:text|format)\("([^"\n]+)"', source))
extension = '\n'.join(p.read_text() for p in (root / 'Sources/FinderExtension').glob('*.swift'))
used.update(re.findall(r'localizedString\(forKey: "([^"\n]+)"', extension))
assert used == en.keys(), f'missing or unused keys: {used ^ en.keys()}'
assert not re.search(r'\b(?:Text|Button|Toggle|Section|Window|MenuBarExtra)\("(?![^"\n]*\\)', source), 'Use L10n for user-facing SwiftUI literals'
print('PASS: English/Ukrainian coverage, placeholders and SwiftUI literals')

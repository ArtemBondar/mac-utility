#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/macutility-localization.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT
python3 "$root/Tests/verify-localization.py"
xcrun swiftc -parse-as-library -module-cache-path "$test_dir/cache" "$root/Tests/LocalizationTests.swift" -o "$test_dir/tests"
"$test_dir/tests" "$root/Sources/MacUtility/Resources"

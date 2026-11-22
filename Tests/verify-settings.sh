#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/macutility-settings.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -module-cache-path "$test_dir/module-cache" "$root/Sources/MacUtility/SettingsStore.swift" "$root/Tests/SettingsStoreTests.swift" -o "$test_dir/settings-tests"
"$test_dir/settings-tests"

#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/macutility-dock-window.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -module-cache-path "$test_dir/module-cache" "$root/Sources/MacUtility/DockVisibility.swift" "$root/Tests/DockWindowIntegrationTests.swift" -o "$test_dir/dock-window-tests"
"$test_dir/dock-window-tests"

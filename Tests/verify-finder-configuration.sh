#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/macutility-finder-config.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -module-cache-path "$test_dir/module-cache" "$root/Sources/MacUtility/FinderConfiguration.swift" "$root/Tests/FinderConfigurationTests.swift" -o "$test_dir/test"
"$test_dir/test"
xcrun swiftc -D DIRECT_DISTRIBUTION -module-cache-path "$test_dir/module-cache" "$root/Sources/MacUtility/FinderConfiguration.swift" "$root/Tests/FinderConfigurationTests.swift" -o "$test_dir/direct-test"
"$test_dir/direct-test"

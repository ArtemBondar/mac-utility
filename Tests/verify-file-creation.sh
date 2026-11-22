#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/macutility-creation.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -module-cache-path "$test_dir/module-cache" "$root/Sources/MacUtility/Localization.swift" "$root/Sources/MacUtility/FileCreation.swift" "$root/Tests/FileCreationTests.swift" -o "$test_dir/tests"
"$test_dir/tests"

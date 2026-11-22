#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/macutility-target.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -module-cache-path "$test_dir/module-cache" "$root/Sources/MacUtility/FinderTargetResolver.swift" "$root/Tests/FinderTargetResolverTests.swift" -o "$test_dir/finder-target-tests"
"$test_dir/finder-target-tests"

#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/macutility-request-tests.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
export CLANG_MODULE_CACHE_PATH="$tmp/module-cache"
xcrun swiftc "$root/Sources/MacUtility/FinderActionRequest.swift" "$root/Tests/FinderActionRequestTests.swift" -o "$tmp/request-tests"
"$tmp/request-tests"
xcrun swiftc "$root/Sources/MacUtility/SecureDirectory.swift" "$root/Sources/MacUtility/FileCreation.swift" "$root/Sources/MacUtility/Localization.swift" "$root/Tests/SecureDirectoryTests.swift" -o "$tmp/directory-tests"
"$tmp/directory-tests"

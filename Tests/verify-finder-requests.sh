#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/macutility-request-tests.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
export CLANG_MODULE_CACHE_PATH="$tmp/module-cache"
xcrun swiftc "$root/Sources/MacUtility/FinderActionRequest.swift" "$root/Tests/FinderActionRequestTests.swift" -o "$tmp/request-tests"
"$tmp/request-tests"
xcrun swiftc -D DIRECT_DISTRIBUTION "$root/Sources/MacUtility/FinderActionRequest.swift" "$root/Tests/FinderActionRequestTests.swift" -o "$tmp/direct-request-tests"
"$tmp/direct-request-tests"
xcrun swiftc "$root/Sources/MacUtility/FinderActionRequest.swift" "$root/Sources/FinderExtension/FinderMenuAction.swift" "$root/Tests/FinderMenuActionTests.swift" -o "$tmp/menu-action-tests"
"$tmp/menu-action-tests"
xcrun swiftc -D DIRECT_DISTRIBUTION "$root/Sources/MacUtility/FinderActionRequest.swift" "$root/Sources/FinderExtension/FinderMenuAction.swift" "$root/Tests/FinderMenuActionTests.swift" -o "$tmp/direct-menu-action-tests"
"$tmp/direct-menu-action-tests"
xcrun swiftc "$root/Sources/MacUtility/SecureDirectory.swift" "$root/Sources/MacUtility/FileCreation.swift" "$root/Sources/MacUtility/Localization.swift" "$root/Tests/SecureDirectoryTests.swift" -o "$tmp/directory-tests"
"$tmp/directory-tests"
xcrun swiftc -D DIRECT_DISTRIBUTION "$root/Sources/MacUtility/FinderActionRequest.swift" "$root/Sources/MacUtility/FinderTargetResolver.swift" "$root/Sources/MacUtility/SecureDirectory.swift" "$root/Sources/MacUtility/FileCreation.swift" "$root/Sources/MacUtility/TerminalLauncher.swift" "$root/Sources/MacUtility/Localization.swift" "$root/Tests/FinderActionPipelineTests.swift" -o "$tmp/pipeline-tests"
"$tmp/pipeline-tests"

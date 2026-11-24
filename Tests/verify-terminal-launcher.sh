#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/macutility-terminal.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -module-cache-path "$test_dir/cache" "$root/Sources/MacUtility/Localization.swift" "$root/Sources/MacUtility/TerminalLauncher.swift" "$root/Tests/TerminalLauncherTests.swift" -o "$test_dir/tests"
"$test_dir/tests"

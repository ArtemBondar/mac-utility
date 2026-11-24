#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/macutility-finder-test.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT
export CLANG_MODULE_CACHE_PATH="$test_dir/module-cache"
xcrun swiftc -module-cache-path "$test_dir/module-cache" \
  "$root/Research/FinderIntegration/ResearchRoot.swift" "$root/Research/FinderIntegration/ContextSummary.swift" "$root/Tests/ResearchRootTests.swift" \
  -o "$test_dir/root-tests"
"$test_dir/root-tests"
bash "$root/Research/FinderIntegration/build.sh" "$test_dir/output"
app="$test_dir/output/MacUtilityResearch.app"
ext="$app/Contents/PlugIns/FinderSync.appex"
plist=/usr/libexec/PlistBuddy
test -x "$app/Contents/MacOS/MacUtilityResearch"
test -x "$ext/Contents/MacOS/FinderSync"
test "$("$plist" -c 'Print :NSServices:0:NSMessage' "$app/Contents/Info.plist")" = inspect
test "$("$plist" -c 'Print :NSExtension:NSExtensionPointIdentifier' "$ext/Contents/Info.plist")" = com.apple.FinderSync
codesign --verify --strict "$ext"
codesign --verify --strict "$app"
for bundle in "$app" "$ext"; do
  codesign -d --entitlements :- "$bundle" > "$test_dir/entitlements.plist" 2>/dev/null
  test "$("$plist" -c 'Print :com.apple.security.app-sandbox' "$test_dir/entitlements.plist")" = true
done
echo 'PASS: diagnostic host, service declaration, Finder Sync bundle, signatures, and sandbox entitlements'

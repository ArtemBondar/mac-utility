#!/bin/bash
set -euo pipefail

# Build in an isolated temporary directory so this test does not modify user
# signing configuration or rely on a previously built product.
project_root="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/macutility-check.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT

xcodebuild -quiet -project "$project_root/MacUtility.xcodeproj" \
  -scheme MacUtility -configuration Debug -derivedDataPath "$test_dir/build" \
  CODE_SIGNING_ALLOWED=NO build

app="$test_dir/build/Build/Products/Debug/MacUtility.app"
extension="$app/Contents/PlugIns/FinderExtension.appex"
# Ad-hoc signing checks bundle structure only. A real App Group requires
# development signing and provisioning; this does not prove runtime access.
codesign --force --sign - --options runtime --entitlements "$project_root/FinderExtension.entitlements" "$extension"
codesign --force --sign - --options runtime --entitlements "$project_root/MacUtility.entitlements" "$app"
info="$app/Contents/Info.plist"
plistbuddy=/usr/libexec/PlistBuddy

test -x "$app/Contents/MacOS/MacUtility"
test -x "$extension/Contents/MacOS/FinderExtension"
test "$("$plistbuddy" -c 'Print :NSExtension:NSExtensionPointIdentifier' "$extension/Contents/Info.plist")" = com.apple.FinderSync
test "$("$plistbuddy" -c 'Print :CFBundleURLTypes:0:CFBundleURLSchemes:0' "$info")" = macutility-finder
for language in en uk; do
  test -f "$app/Contents/Resources/$language.lproj/Localizable.strings"
done
test "$("$plistbuddy" -c 'Print :CFBundlePackageType' "$info")" = APPL
test "$("$plistbuddy" -c 'Print :LSUIElement' "$info")" = true
test "$("$plistbuddy" -c 'Print :LSMinimumSystemVersion' "$info")" = 13.0
codesign --verify --strict --deep "$app"
codesign --verify --strict "$extension"
codesign -d --entitlements :- "$app" >"$test_dir/entitlements.plist" 2>/dev/null
test "$("$plistbuddy" -c 'Print :com.apple.security.app-sandbox' "$test_dir/entitlements.plist")" = true
test "$("$plistbuddy" -c 'Print :com.apple.security.files.user-selected.read-write' "$test_dir/entitlements.plist")" = true
test "$("$plistbuddy" -c 'Print :com.apple.security.files.bookmarks.app-scope' "$test_dir/entitlements.plist")" = true
test "$("$plistbuddy" -c 'Print :com.apple.security.application-groups:0' "$test_dir/entitlements.plist")" = group.com.example.MacUtility
codesign -d --entitlements :- "$extension" >"$test_dir/extension-entitlements.plist" 2>/dev/null
test "$("$plistbuddy" -c 'Print :com.apple.security.application-groups:0' "$test_dir/extension-entitlements.plist")" = group.com.example.MacUtility
codesign -dv "$app" 2>"$test_dir/signature.txt"
grep -q 'Signature=adhoc' "$test_dir/signature.txt"
grep -q 'runtime' "$test_dir/signature.txt"

printf '%s\n' 'PASS: app bundle, deployment target, accessory mode, sandbox, hardened runtime, and ad-hoc signature'

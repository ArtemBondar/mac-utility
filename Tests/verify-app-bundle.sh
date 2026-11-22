#!/bin/bash
set -euo pipefail

# Build in an isolated temporary directory so this test does not modify user
# signing configuration or rely on a previously built product.
project_root="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/macutility-check.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT

xcodebuild -quiet -project "$project_root/MacUtility.xcodeproj" \
  -scheme MacUtility -configuration Debug -derivedDataPath "$test_dir/build" \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO build

app="$test_dir/build/Build/Products/Debug/MacUtility.app"
info="$app/Contents/Info.plist"
plistbuddy=/usr/libexec/PlistBuddy

test -x "$app/Contents/MacOS/MacUtility"
for language in en uk; do
  test -f "$app/Contents/Resources/$language.lproj/Localizable.strings"
done
test "$("$plistbuddy" -c 'Print :CFBundlePackageType' "$info")" = APPL
test "$("$plistbuddy" -c 'Print :LSUIElement' "$info")" = true
test "$("$plistbuddy" -c 'Print :LSMinimumSystemVersion' "$info")" = 13.0
codesign --verify --strict --deep "$app"
codesign -d --entitlements :- "$app" >"$test_dir/entitlements.plist" 2>/dev/null
test "$("$plistbuddy" -c 'Print :com.apple.security.app-sandbox' "$test_dir/entitlements.plist")" = true
test "$("$plistbuddy" -c 'Print :com.apple.security.files.user-selected.read-write' "$test_dir/entitlements.plist")" = true
test "$("$plistbuddy" -c 'Print :com.apple.security.files.bookmarks.app-scope' "$test_dir/entitlements.plist")" = true
codesign -dv "$app" 2>"$test_dir/signature.txt"
grep -q 'Signature=adhoc' "$test_dir/signature.txt"
grep -q 'runtime' "$test_dir/signature.txt"

printf '%s\n' 'PASS: app bundle, deployment target, accessory mode, sandbox, hardened runtime, and ad-hoc signature'

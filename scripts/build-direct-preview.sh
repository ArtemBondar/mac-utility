#!/bin/bash
# Local Direct preview: host is not sandboxed; Finder extension is sandboxed.
# The artifact is ad-hoc signed, not notarized or suitable for the Mac App Store.
set -euo pipefail
if [[ $# -ne 1 || -e "$1" ]]; then
  echo 'Usage: bash scripts/build-direct-preview.sh <new-output-directory>' >&2
  exit 2
fi
root="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$1"
output="$(cd "$1" && pwd)"
build="$(mktemp -d "${TMPDIR:-/tmp}/macutility-direct.XXXXXX")"
trap 'rm -rf "$build"' EXIT
xcodebuild -quiet -project "$root/MacUtility.xcodeproj" -scheme MacUtility -configuration Direct \
  -derivedDataPath "$build" CODE_SIGNING_ALLOWED=NO build
ditto "$build/Build/Products/Direct/MacUtility.app" "$output/MacUtility.app"
app="$output/MacUtility.app"
extension="$app/Contents/PlugIns/FinderExtension.appex"
codesign --force --sign - --options runtime --entitlements "$root/FinderExtension-Direct.entitlements" "$extension"
codesign --force --sign - --options runtime "$app"
codesign --verify --strict --deep "$app"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleURLTypes:0:CFBundleURLSchemes:0' "$app/Contents/Info.plist")" = macutility-finder-direct
codesign -d --entitlements :- "$extension" > "$build/extension-entitlements.plist" 2>/dev/null
test "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.app-sandbox' "$build/extension-entitlements.plist")" = true
ditto -c -k --sequesterRsrc --keepParent "$app" "$output/MacUtility-direct-preview.zip"
echo "Created $output/MacUtility-direct-preview.zip (ad-hoc signed, not notarized)."

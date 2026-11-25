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
# Finder can keep an older same-version extension registered from another app
# copy. Give previews a valid, increasing numeric version before signing them.
preview_version="$(python3 -c 'from datetime import datetime, timezone, date; now = datetime.now(timezone.utc); print(f"{(now.date() - date(2020, 1, 1)).days + 1}.{now.hour}.{now.minute}")')"
xcodebuild -quiet -project "$root/MacUtility.xcodeproj" -scheme MacUtility -configuration Direct \
  -derivedDataPath "$build" CODE_SIGNING_ALLOWED=NO CURRENT_PROJECT_VERSION="$preview_version" build
ditto "$build/Build/Products/Direct/Clicklet.app" "$output/Clicklet.app"
app="$output/Clicklet.app"
extension="$app/Contents/PlugIns/FinderExtension.appex"
codesign --force --sign - --options runtime --entitlements "$root/FinderExtension-Direct.entitlements" "$extension"
codesign --force --sign - --options runtime "$app"
codesign --verify --strict --deep "$app"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleURLTypes:0:CFBundleURLSchemes:0' "$app/Contents/Info.plist")" = macutility-finder-direct
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$app/Contents/Info.plist")" = Clicklet
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app/Contents/Info.plist")" = MacUtility
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist")" = com.example.MacUtilityDirect
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$app/Contents/Info.plist")" = "$preview_version"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$extension/Contents/Info.plist")" = "$preview_version"
codesign -d --entitlements :- "$extension" > "$build/extension-entitlements.plist" 2>/dev/null
test "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.app-sandbox' "$build/extension-entitlements.plist")" = true
ditto -c -k --sequesterRsrc --keepParent "$app" "$output/Clicklet-direct-preview.zip"
echo "Created $output/Clicklet-direct-preview.zip (ad-hoc signed, not notarized)."

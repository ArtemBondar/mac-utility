#!/bin/bash
# Create an ad-hoc signed preview, not a notarized distribution release.
set -euo pipefail
if [[ $# -ne 1 || -e "$1" ]]; then
  echo 'Usage: bash scripts/build-preview.sh <new-output-directory>' >&2
  exit 2
fi
root="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$1"
output="$(cd "$1" && pwd)"
build="$(mktemp -d "${TMPDIR:-/tmp}/macutility-release.XXXXXX")"
trap 'rm -rf "$build"' EXIT
xcodebuild -quiet -project "$root/MacUtility.xcodeproj" -scheme MacUtility -configuration Release \
  -derivedDataPath "$build" CODE_SIGNING_ALLOWED=NO build
app="$build/Build/Products/Release/MacUtility.app"
extension="$app/Contents/PlugIns/FinderExtension.appex"
codesign --force --sign - --options runtime --entitlements "$root/FinderExtension.entitlements" "$extension"
codesign --force --sign - --options runtime --entitlements "$root/MacUtility.entitlements" "$app"
codesign --verify --strict --deep "$app"
ditto -c -k --sequesterRsrc --keepParent "$app" "$output/MacUtility-preview.zip"
echo "Created $output/MacUtility-preview.zip (ad-hoc signed, not notarized)."

#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 || -e "$1" ]]; then
  echo "Usage: bash build.sh <new-output-directory>" >&2
  exit 2
fi
root="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$1"
out="$(cd "$1" && pwd)"
app="$out/MacUtilityResearch.app"
ext="$app/Contents/PlugIns/FinderSync.appex"
mkdir -p "$app/Contents/MacOS" "$ext/Contents/MacOS"
cp "$root/Host-Info.plist" "$app/Contents/Info.plist"
cp "$root/Extension-Info.plist" "$ext/Contents/Info.plist"
export CLANG_MODULE_CACHE_PATH="$out/module-cache"
xcrun swiftc -module-cache-path "$out/module-cache" -target "$(uname -m)-apple-macos13.0" "$root/Host.swift" -o "$app/Contents/MacOS/MacUtilityResearch"
xcrun swiftc -module-name MacUtilityResearchExtension -module-cache-path "$out/module-cache" -target "$(uname -m)-apple-macos13.0" -parse-as-library \
  "$root/FinderSync.swift" "$root/ResearchRoot.swift" "$root/ContextSummary.swift" -framework FinderSync -framework AppKit \
  -Xlinker -e -Xlinker _NSExtensionMain -o "$ext/Contents/MacOS/FinderSync"
codesign --force --sign - --options runtime --entitlements "$root/Entitlements.plist" "$ext"
codesign --force --sign - --options runtime --entitlements "$root/Entitlements.plist" "$app"
echo "Built diagnostic app: $app"

#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
configuration="${1:-release}"
app_dir="$project_dir/dist/Codex Usage Bar.app"
contents_dir="$app_dir/Contents"
iconset_dir="$project_dir/.build/AppIcon.iconset"
assets_dir="$project_dir/.build/Assets.xcassets"
appicon_dir="$assets_dir/AppIcon.appiconset"
compiled_assets_dir="$(mktemp -d "$project_dir/.build/CompiledAssets.XXXXXX")"
bundle_identifier="${CODEX_USAGE_BAR_BUNDLE_ID:-app.codexusagebar.macos}"
app_version="${CODEX_USAGE_BAR_VERSION:-1.0.0}"
build_number="${CODEX_USAGE_BAR_BUILD:-1}"
sign_identity="${CODEX_USAGE_BAR_SIGN_IDENTITY:--}"

cd "$project_dir"
export CLANG_MODULE_CACHE_PATH="$project_dir/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$project_dir/.build/swiftpm-cache"
swift build -c "$configuration" --disable-sandbox
binary_path="$(swift build -c "$configuration" --disable-sandbox --show-bin-path)/CodexUsageBar"

mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"
mkdir -p "$iconset_dir"
sips -z 16 16 "$project_dir/Resources/AppIcon.png" --out "$iconset_dir/icon_16x16.png" >/dev/null
sips -z 32 32 "$project_dir/Resources/AppIcon.png" --out "$iconset_dir/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$project_dir/Resources/AppIcon.png" --out "$iconset_dir/icon_32x32.png" >/dev/null
sips -z 64 64 "$project_dir/Resources/AppIcon.png" --out "$iconset_dir/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$project_dir/Resources/AppIcon.png" --out "$iconset_dir/icon_128x128.png" >/dev/null
sips -z 256 256 "$project_dir/Resources/AppIcon.png" --out "$iconset_dir/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$project_dir/Resources/AppIcon.png" --out "$iconset_dir/icon_256x256.png" >/dev/null
sips -z 512 512 "$project_dir/Resources/AppIcon.png" --out "$iconset_dir/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$project_dir/Resources/AppIcon.png" --out "$iconset_dir/icon_512x512.png" >/dev/null
cp "$project_dir/Resources/AppIcon.png" "$iconset_dir/icon_512x512@2x.png"
mkdir -p "$appicon_dir"
cp "$iconset_dir"/*.png "$appicon_dir/"
cp "$project_dir/Resources/AppIconContents.json" "$appicon_dir/Contents.json"
xcrun actool "$assets_dir" \
    --compile "$compiled_assets_dir" \
    --platform macosx \
    --minimum-deployment-target 14.0 \
    --app-icon AppIcon \
    --output-partial-info-plist "$project_dir/.build/AppIconInfo.plist" >/dev/null

cp "$binary_path" "$contents_dir/MacOS/CodexUsageBar"
cp "$project_dir/Resources/Info.plist" "$contents_dir/Info.plist"
cp "$compiled_assets_dir/AppIcon.icns" "$contents_dir/Resources/AppIcon.icns"
cp "$compiled_assets_dir/Assets.car" "$contents_dir/Resources/Assets.car"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $bundle_identifier" "$contents_dir/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $app_version" "$contents_dir/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $build_number" "$contents_dir/Info.plist"
chmod +x "$contents_dir/MacOS/CodexUsageBar"

codesign --force --deep --sign "$sign_identity" "$app_dir"
echo "$app_dir"

#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
app_path="${1:-$project_dir/dist/Codex Usage Bar.app}"
archive_path="${2:-$project_dir/dist/Codex-Usage-Bar.zip}"

if [[ ! -d "$app_path" ]]; then
    echo "Application bundle not found: $app_path"
    exit 1
fi

if [[ -z "${CODEX_USAGE_BAR_SIGN_IDENTITY:-}" || "$CODEX_USAGE_BAR_SIGN_IDENTITY" == "-" ]]; then
    echo "A Developer ID Application signing identity is required for notarization."
    exit 1
fi

codesign --verify --deep --strict "$app_path"
ditto -c -k --sequesterRsrc --keepParent "$app_path" "$archive_path"

if [[ -n "${CODEX_USAGE_BAR_NOTARY_PROFILE:-}" ]]; then
    xcrun notarytool submit "$archive_path" \
        --keychain-profile "$CODEX_USAGE_BAR_NOTARY_PROFILE" \
        --wait
elif [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
    xcrun notarytool submit "$archive_path" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$APPLE_APP_SPECIFIC_PASSWORD" \
        --wait
else
    echo "Provide CODEX_USAGE_BAR_NOTARY_PROFILE or Apple notarization credentials."
    exit 1
fi

xcrun stapler staple "$app_path"
xcrun stapler validate "$app_path"
spctl --assess --type execute --verbose=4 "$app_path"

rm -f "$archive_path"
ditto -c -k --sequesterRsrc --keepParent "$app_path" "$archive_path"
archive_directory="${archive_path:h}"
archive_filename="${archive_path:t}"
(
    cd "$archive_directory"
    shasum -a 256 "$archive_filename" > "$archive_filename.sha256"
)

echo "$archive_path"

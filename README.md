<p align="center">
  <img src="Resources/AppIcon.png" width="160" alt="Codex Usage Bar icon">
</p>

<h1 align="center">Codex Usage Bar</h1>

<p align="center">
  A private, native macOS menu bar app for monitoring your remaining Codex usage.
</p>

<p align="center"><a href="README.tr.md">Türkçe</a></p>

## Features

- Shows the remaining 5-hour and weekly percentages as `96% | 36%`
- Can show both limits, either limit alone, and swap their order
- Displays exact reset dates and times together with a live countdown
- Refreshes every 15–120 seconds and reacts to live rate-limit notifications
- Uses four color bands: green, yellow, orange, and red
- Shows the detected ChatGPT plan and available reset-credit count
- Lets you select the ChatGPT/Codex app or `codex` executable in Settings
- Optionally launches at login through the native macOS Login Items service
- Includes a first-run connection check, Applications-folder warning, and launch-at-login choice
- Optionally notifies once when either remaining limit crosses below 25%
- Checks GitHub Releases for updates, with an opt-out and manual check
- Copies a privacy-safe diagnostics report and links to GitHub, privacy, and issue reporting
- Provides English and Turkish user interfaces based on the macOS language setting
- Runs as a menu bar accessory without a Dock icon

## Privacy

Codex Usage Bar never asks for, stores, or logs an API key, OAuth token, email address, or account ID. It launches the locally installed Codex App Server and requests only the rate-limit snapshot. Authentication remains managed by your existing local Codex installation.

Only non-sensitive preferences are stored in macOS `UserDefaults`:

- Optional path to the ChatGPT/Codex app or `codex` executable
- Refresh interval
- Whether the one-time onboarding window has been completed
- Menu bar display mode and percentage order
- Whether automatic update checks and low-usage notifications are enabled

The launch-at-login choice and notification authorization are managed by macOS. Usage snapshots and notification threshold comparisons stay in memory and are discarded when the app exits. The app checks the public GitHub Releases API at launch and approximately every six hours when automatic checks are enabled, sending only its app version in the user-agent. It never sends Codex credentials or account data to GitHub and never downloads or installs an update automatically.

See [PRIVACY.md](PRIVACY.md) for the complete data-flow description.

## Requirements

- macOS 14 or later
- ChatGPT Desktop, Codex Desktop, or Codex CLI with an active ChatGPT login
- Xcode 16+ / Swift 6 when building from source

## Install a release

1. Download and extract the `.zip` file from GitHub Releases.
2. Move `Codex Usage Bar.app` to the Applications folder.
3. The current public release is ad-hoc signed because the project does not yet use a paid Apple Developer membership. If macOS blocks the first launch, Control-click the app, select **Open**, and confirm. You can also use **System Settings → Privacy & Security → Open Anyway**.
4. The app detects a signed-in ChatGPT Desktop, Codex Desktop, or Codex CLI installation automatically.

## Run from source

```bash
swift run CodexUsageBar
```

## Build the app

```bash
Scripts/package_app.sh
open "dist/Codex Usage Bar.app"
```

The script creates an ad-hoc-signed app at `dist/Codex Usage Bar.app`. You can customize the bundle identifier without editing tracked files:

```bash
CODEX_USAGE_BAR_BUNDLE_ID=io.github.YOUR_USERNAME.CodexUsageBar Scripts/package_app.sh
```

For Developer ID distribution, set `CODEX_USAGE_BAR_SIGN_IDENTITY` to your certificate name. `CODEX_USAGE_BAR_VERSION` and `CODEX_USAGE_BAR_BUILD` override the two bundle version fields.

To notarize a signed build locally, first store a `notarytool` keychain profile and then run:

```bash
CODEX_USAGE_BAR_SIGN_IDENTITY="Developer ID Application: Example (TEAMID)" Scripts/package_app.sh
CODEX_USAGE_BAR_SIGN_IDENTITY="Developer ID Application: Example (TEAMID)" \
CODEX_USAGE_BAR_NOTARY_PROFILE="notarytool-profile" Scripts/notarize_app.sh
```

When all of the following encrypted GitHub Actions secrets are available, the release workflow creates a Developer ID-signed and notarized build:

- `APPLE_CERTIFICATE_P12_BASE64`
- `APPLE_CERTIFICATE_PASSWORD`
- `APPLE_SIGNING_IDENTITY`
- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`

Without a complete signing configuration, the same workflow intentionally publishes an explicitly named `-ad-hoc.zip` archive and documents the first-launch Gatekeeper step in the release notes.

## Settings

Open the menu bar popover and select the gear button. You can choose the displayed limits and their order, refresh interval, automatic update checks, low-usage notifications, launch at login, and an optional custom Codex executable. Launch at login and notifications are off by default. The diagnostics button copies only coarse technical state—it excludes local paths, account details, usage percentages, and error text.

## How it works

The app starts `codex app-server --stdio`, completes the documented JSON-RPC initialization handshake, and reads `account/rateLimits/read`. It calculates remaining allowance as `100 - usedPercent` and listens for `account/rateLimits/updated` invalidation notifications.

This project uses the stable App Server surface with `experimentalApi` disabled. See the [official Codex App Server documentation](https://developers.openai.com/codex/app-server).

## Development

```bash
swift test
Scripts/check_repository.sh
```

Pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md) before submitting changes.

## Disclaimer

Codex Usage Bar is an independent open-source project. It is not affiliated with, endorsed by, or sponsored by OpenAI. “OpenAI”, “ChatGPT”, and “Codex” are trademarks of their respective owner.

## License

[MIT](LICENSE)

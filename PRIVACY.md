# Privacy

Codex Usage Bar is designed to minimize access to account data.

## Data read

The app requests the Codex rate-limit snapshot from the locally installed Codex App Server. It decodes only:

- Used percentage, window duration, and reset timestamp
- Plan type
- Available rate-limit reset count

The backend response can contain an account identifier. The app deliberately does not declare, decode, retain, display, persist, or log that field.

## Data stored

The app stores only the following local preferences in macOS `UserDefaults`:

- `codexExecutablePath`: an optional local filesystem path
- `refreshInterval`: the selected polling interval
- `hasCompletedOnboarding`: whether the one-time welcome window has been dismissed
- `menuBarDisplayMode`: which limits are visible in the menu bar
- `weeklyFirst`: the order of the two menu bar percentages
- `automaticUpdateChecks`: whether periodic GitHub release checks are enabled
- `notificationsEnabled`: whether low-usage notifications are enabled

Usage snapshots and notification threshold comparisons remain in memory and are discarded when the app exits. The app does not build or persist usage history.

If launch at login is enabled, its registration state is stored and managed by the native macOS Login Items service. The app does not add another preference or install a separate launch-agent file.

If low-usage notifications are enabled, macOS manages notification authorization and delivered-notification history. The app asks for permission in response to the Settings toggle and schedules a notification only when either remaining limit crosses from 25% or higher to below 25%.

## Credentials

The app never asks for or stores API keys, passwords, OAuth tokens, account IDs, or email addresses. Authentication is managed by the user's existing local Codex installation. Standard error output from the Codex child process is discarded and is not written to disk or shown in the UI.

## Network and telemetry

The app contains no analytics, advertising, crash-reporting SDK, or third-party dependency. Any network communication required to retrieve rate limits is performed by the local Codex App Server.

When automatic checks are enabled, the app checks the public GitHub Releases API at launch and approximately every six hours to determine whether a newer version is available. The request contains the installed app version in its user-agent and does not contain Codex credentials or account data. The app does not download or install updates automatically.

The optional diagnostics report contains only the app/build version, macOS version, CPU architecture, locale, coarse app-location and Codex-source categories, and feature/connection states. It deliberately excludes filesystem paths, account information, credentials, usage percentages, and error text.

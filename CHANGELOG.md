# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.1] - 2026-09-10

### Fixed

- Menu bar display and ordering choices now apply immediately instead of waiting for another refresh event
- Release checksum files now use portable archive names

### Added

- One-click copy to Applications, relaunch, and launch-at-login activation when the app is running elsewhere

## [1.1.0] - 2026-09-10

### Added

- Optional launch at login using the native macOS Login Items service
- First-run onboarding with a live local Codex connection check
- Automatic and manual GitHub Releases update checks
- English and Turkish application localization
- Developer ID signing, hardened runtime, notarization, stapling, and checksum release automation
- Release installation and first-launch instructions
- Configurable menu bar limit selection and percentage order
- Reset countdowns beside exact reset dates and times
- Opt-in notifications when either remaining limit crosses below 25%
- Applications-folder warning and launch-at-login choice during onboarding
- Automatic update-check opt-out with manual checks still available
- Privacy-safe copyable diagnostics and About links
- Ad-hoc GitHub release fallback when Developer ID secrets are unavailable

## [1.0.0] - 2026-09-09

### Added

- Native macOS menu bar display for 5-hour and weekly remaining usage
- Exact reset times and four 25-point color bands
- Live rate-limit notifications and configurable polling
- Settings for Codex executable discovery and refresh interval
- Privacy-first response decoding with no credential or account-ID storage
- Custom application icon and ad-hoc app packaging

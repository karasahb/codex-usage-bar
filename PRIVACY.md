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

Usage snapshots remain in memory and are discarded when the app exits.

## Credentials

The app never asks for or stores API keys, passwords, OAuth tokens, account IDs, or email addresses. Authentication is managed by the user's existing local Codex installation. Standard error output from the Codex child process is discarded and is not written to disk or shown in the UI.

## Network and telemetry

The app contains no analytics, advertising, crash-reporting SDK, or third-party dependency. Any network communication required to retrieve rate limits is performed by the local Codex App Server.

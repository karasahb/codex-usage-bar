# Contributing

Thank you for helping improve Codex Usage Bar.

## Before opening a pull request

1. Keep the app dependency-free unless a dependency is clearly justified.
2. Do not add account identifiers, tokens, email addresses, absolute personal paths, or captured rate-limit payloads.
3. Preserve accessibility labels and VoiceOver behavior.
4. Run:

   ```bash
   swift test
   Scripts/check_repository.sh
   Scripts/package_app.sh
   ```

5. Describe user-visible changes and include tests for parsing or threshold behavior.

## Style

- Prefer small native SwiftUI/AppKit components.
- Keep JSON-RPC decoding strict for fields the app uses and ignore unrelated backend fields.
- Store only explicit, non-sensitive user preferences.
- Keep user-facing Turkish copy concise and consistent.

import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var store: UsageStore
    @ObservedObject var launchAtLogin: LaunchAtLoginManager
    @ObservedObject var updateChecker: UpdateChecker

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Codex Usage Bar")
                        .font(.title2.weight(.semibold))
                    Text(L10n.string("app.subtitle", fallback: "Connection and application settings"))
                        .foregroundStyle(.secondary)
                }
            }

            GroupBox(L10n.string("connection.group", fallback: "Codex Connection")) {
                VStack(alignment: .leading, spacing: 10) {
                    TextField(
                        L10n.string("connection.auto_detect", fallback: "Detect automatically"),
                        text: $settings.codexExecutablePath
                    )
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Button(
                            L10n.string("connection.choose", fallback: "Choose…"),
                            action: chooseCodexExecutable
                        )
                        Button(L10n.string("connection.use_automatic", fallback: "Use Automatic")) {
                            settings.useAutomaticCodexLocation()
                        }
                        .disabled(settings.normalizedCodexExecutablePath == nil)
                        Spacer()
                    }

                    Text(effectivePathText)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .padding(.top, 4)
            }

            GroupBox(L10n.string("refresh.group", fallback: "Refresh")) {
                Picker(
                    L10n.string("refresh.frequency", fallback: "Check frequency"),
                    selection: $settings.refreshInterval
                ) {
                    ForEach(AppSettings.allowedRefreshIntervals, id: \.self) { seconds in
                        Text(
                            L10n.format(
                                "refresh.seconds",
                                fallback: "%d seconds",
                                Int(seconds)
                            )
                        )
                        .tag(seconds)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.top, 4)
            }

            GroupBox(L10n.string("startup.group", fallback: "Startup")) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(
                        L10n.string("startup.toggle", fallback: "Launch at login"),
                        isOn: Binding(
                            get: { launchAtLogin.state.isSelected },
                            set: { launchAtLogin.setEnabled($0) }
                        )
                    )
                    .disabled(launchAtLogin.state == .unavailable)

                    if launchAtLogin.state == .requiresApproval {
                        HStack {
                            Text(
                                L10n.string(
                                    "startup.approval_required",
                                    fallback: "macOS approval is required."
                                )
                            )
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Spacer()
                            Button(
                                L10n.string("startup.open_login_items", fallback: "Open Login Items")
                            ) {
                                launchAtLogin.openSystemSettings()
                            }
                        }
                    } else if launchAtLogin.state == .unavailable {
                        Text(
                            L10n.string(
                                "startup.unavailable",
                                fallback: "This feature is available only in the packaged app in the Applications folder."
                            )
                        )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let message = launchAtLogin.errorMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 4)
            }

            GroupBox(L10n.string("update.group", fallback: "Updates")) {
                HStack(spacing: 10) {
                    updateStatus
                    Spacer()
                    Button(L10n.string("update.check", fallback: "Check for Updates")) {
                        updateChecker.check()
                    }
                    .disabled(updateChecker.state == .checking)
                }
                .padding(.top, 4)
            }

            GroupBox(L10n.string("privacy.group", fallback: "Privacy")) {
                Label {
                    Text(
                        L10n.string(
                            "privacy.summary",
                            fallback: "The app does not store tokens, API keys, email addresses, or account identifiers. The Codex path and refresh interval are stored on this Mac; launch at login is managed by macOS Login Items."
                        )
                    )
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(.green)
                }
                .padding(.top, 4)
            }

            HStack {
                if let message = store.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
                Spacer()
                Button(L10n.string("connection.refresh", fallback: "Reconnect")) {
                    store.reconnect()
                }
            }
        }
        .padding(22)
        .frame(width: 520)
        .onAppear {
            launchAtLogin.refresh()
        }
    }

    @ViewBuilder
    private var updateStatus: some View {
        switch updateChecker.state {
        case .idle:
            Text(L10n.string("update.check", fallback: "Check for Updates"))
                .foregroundStyle(.secondary)
        case .checking:
            HStack(spacing: 7) {
                ProgressView().controlSize(.small)
                Text(L10n.string("update.checking", fallback: "Checking for updates…"))
            }
            .foregroundStyle(.secondary)
        case .current:
            Label(
                L10n.string("update.current", fallback: "Codex Usage Bar is up to date."),
                systemImage: "checkmark.circle.fill"
            )
            .foregroundStyle(.green)
        case .available(let version, let url):
            HStack(spacing: 8) {
                Text(L10n.format("update.available", fallback: "Version %@ is available.", version))
                Link(L10n.string("common.download", fallback: "Download"), destination: url)
            }
            .foregroundStyle(.blue)
        case .failed(let message):
            Text(L10n.format("update.failed", fallback: "Could not check for updates: %@", message))
                .foregroundStyle(.red)
                .lineLimit(2)
        }
    }

    private var effectivePathText: String {
        if let customPath = settings.normalizedCodexExecutablePath {
            if let resolved = CodexAppServerClient.resolveConfiguredExecutable(customPath) {
                return L10n.format(
                    "connection.path_in_use",
                    fallback: "Path in use: %@",
                    resolved.path
                )
            }
            return L10n.string(
                "connection.invalid_path",
                fallback: "The selected path is not a valid Codex app or executable."
            )
        }
        if let detected = CodexAppServerClient.autoDetectedExecutable() {
            return L10n.format(
                "connection.path_detected",
                fallback: "Detected automatically: %@",
                detected.path
            )
        }
        return L10n.string(
            "connection.not_found",
            fallback: "The Codex executable has not been found yet."
        )
    }

    private func chooseCodexExecutable() {
        let panel = NSOpenPanel()
        panel.title = L10n.string(
            "connection.file_picker_title",
            fallback: "Choose the ChatGPT/Codex app or codex executable"
        )
        panel.prompt = L10n.string("common.choose", fallback: "Choose")
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.treatsFilePackagesAsDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            settings.codexExecutablePath = url.path
        }
    }
}

import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var store: UsageStore
    @ObservedObject var launchAtLogin: LaunchAtLoginManager
    @ObservedObject var updateChecker: UpdateChecker
    @ObservedObject var notificationManager: UsageNotificationManager
    @State private var diagnosticsCopied = false

    var body: some View {
        ScrollView {
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

            GroupBox(L10n.string("menu_bar.group", fallback: "Menu Bar")) {
                VStack(alignment: .leading, spacing: 10) {
                    Picker(
                        L10n.string("menu_bar.display", fallback: "Show"),
                        selection: $settings.menuBarDisplayMode
                    ) {
                        Text(L10n.string("menu_bar.both", fallback: "Both")).tag(MenuBarDisplayMode.both)
                        Text(L10n.string("menu_bar.five_hour", fallback: "5-hour only")).tag(MenuBarDisplayMode.fiveHour)
                        Text(L10n.string("menu_bar.weekly", fallback: "Weekly only")).tag(MenuBarDisplayMode.weekly)
                    }
                    .pickerStyle(.segmented)

                    Toggle(
                        L10n.string("menu_bar.weekly_first", fallback: "Show weekly percentage first"),
                        isOn: $settings.weeklyFirst
                    )
                    .disabled(settings.menuBarDisplayMode != .both)
                }
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
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(
                        L10n.string("update.automatic", fallback: "Check for updates automatically"),
                        isOn: $settings.automaticUpdateChecks
                    )
                    HStack(spacing: 10) {
                        updateStatus
                        Spacer()
                        Button(L10n.string("update.check", fallback: "Check for Updates")) {
                            updateChecker.check()
                        }
                        .disabled(updateChecker.state == .checking)
                    }
                }
                .padding(.top, 4)
            }

            GroupBox(L10n.string("notification.group", fallback: "Notifications")) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(
                        L10n.string(
                            "notification.toggle",
                            fallback: "Notify me when remaining usage falls below 25%"
                        ),
                        isOn: $settings.notificationsEnabled
                    )

                    Text(notificationStatusText)
                        .font(.caption)
                        .foregroundStyle(
                            notificationManager.authorizationState == .denied ? .orange : .secondary
                        )
                        .fixedSize(horizontal: false, vertical: true)

                    if let message = notificationManager.errorMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.top, 4)
            }

            GroupBox(L10n.string("privacy.group", fallback: "Privacy")) {
                Label {
                    Text(
                        L10n.string(
                            "privacy.summary",
                            fallback: "The app does not store tokens, API keys, email addresses, account identifiers, or usage history. Preferences stay on this Mac; launch at login and notification permission are managed by macOS."
                        )
                    )
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(.green)
                }
                .padding(.top, 4)
            }

            GroupBox(L10n.string("diagnostics.group", fallback: "Diagnostics")) {
                HStack {
                    Text(
                        L10n.string(
                            "diagnostics.summary",
                            fallback: "Copies technical status without account details, paths, usage percentages, or error text."
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button(
                        diagnosticsCopied
                            ? L10n.string("diagnostics.copied", fallback: "Copied")
                            : L10n.string("diagnostics.copy", fallback: "Copy Diagnostics")
                    ) {
                        copyDiagnostics()
                    }
                }
                .padding(.top, 4)
            }

            GroupBox(L10n.string("about.group", fallback: "About")) {
                VStack(alignment: .leading, spacing: 9) {
                    Text(versionText)
                        .font(.callout.weight(.medium))
                    HStack(spacing: 14) {
                        Link(
                            L10n.string("about.github", fallback: "GitHub"),
                            destination: URL(string: "https://github.com/karasahb/codex-usage-bar")!
                        )
                        Link(
                            L10n.string("about.privacy", fallback: "Privacy Policy"),
                            destination: URL(string: "https://github.com/karasahb/codex-usage-bar/blob/main/PRIVACY.md")!
                        )
                        Link(
                            L10n.string("about.issue", fallback: "Report an Issue"),
                            destination: URL(string: "https://github.com/karasahb/codex-usage-bar/issues/new/choose")!
                        )
                    }
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
        }
        .frame(width: 560, height: 720)
        .onAppear {
            launchAtLogin.refresh()
            notificationManager.refreshAuthorization()
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

    private var notificationStatusText: String {
        if !settings.notificationsEnabled {
            return L10n.string("notification.off", fallback: "Notifications are off.")
        }
        switch notificationManager.authorizationState {
        case .unknown:
            return L10n.string(
                "notification.permission_pending",
                fallback: "macOS will ask for permission before the first notification can be delivered."
            )
        case .authorized:
            return L10n.string(
                "notification.ready",
                fallback: "Ready. Each limit is reported once when it crosses below 25%."
            )
        case .denied:
            return L10n.string(
                "notification.denied",
                fallback: "Notification permission is blocked in macOS System Settings."
            )
        }
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "development"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
            ?? "development"
        return L10n.format("about.version", fallback: "Version %@ (%@)", version, build)
    }

    private func copyDiagnostics() {
        let report = DiagnosticsReport.current(
            settings: settings,
            store: store,
            launchAtLogin: launchAtLogin,
            notificationAuthorization: notificationManager.authorizationState
        )
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(report, forType: .string)
        diagnosticsCopied = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            diagnosticsCopied = false
        }
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

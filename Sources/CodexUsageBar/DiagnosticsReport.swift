import Foundation

enum CodexSourceCategory: String {
    case chatGPTDesktop = "ChatGPT Desktop"
    case codexDesktop = "Codex Desktop"
    case homebrewCLI = "Homebrew Codex CLI"
    case customExecutable = "Custom executable"
    case notFound = "Not found"

    static func detect(configuredPath: String?) -> Self {
        if let configuredPath, !configuredPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return classify(configuredPath)
        }
        guard let detected = CodexAppServerClient.autoDetectedExecutable() else { return .notFound }
        return classify(detected.path)
    }

    private static func classify(_ path: String) -> Self {
        if path.contains("/ChatGPT.app/") || path.hasSuffix("/ChatGPT.app") {
            return .chatGPTDesktop
        }
        if path.contains("/Codex.app/") || path.hasSuffix("/Codex.app") {
            return .codexDesktop
        }
        if path == "/opt/homebrew/bin/codex" || path == "/usr/local/bin/codex" {
            return .homebrewCLI
        }
        return .customExecutable
    }
}

enum DiagnosticsReport {
    @MainActor
    static func current(
        settings: AppSettings,
        store: UsageStore,
        launchAtLogin: LaunchAtLoginManager,
        notificationAuthorization: NotificationAuthorizationState
    ) -> String {
        make(
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development",
            build: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "development",
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            architecture: currentArchitecture,
            localeIdentifier: Locale.autoupdatingCurrent.identifier,
            appLocation: ApplicationLocation.category(),
            codexSource: CodexSourceCategory.detect(configuredPath: settings.normalizedCodexExecutablePath),
            connectionState: store.snapshot != nil ? "Connected" : (store.isRefreshing ? "Connecting" : "Unavailable"),
            launchAtLogin: String(describing: launchAtLogin.state),
            automaticUpdates: settings.automaticUpdateChecks,
            notifications: settings.notificationsEnabled,
            notificationAuthorization: notificationAuthorization
        )
    }

    static func make(
        appVersion: String,
        build: String,
        osVersion: String,
        architecture: String,
        localeIdentifier: String,
        appLocation: ApplicationLocationCategory,
        codexSource: CodexSourceCategory,
        connectionState: String,
        launchAtLogin: String,
        automaticUpdates: Bool,
        notifications: Bool,
        notificationAuthorization: NotificationAuthorizationState
    ) -> String {
        [
            "Codex Usage Bar diagnostics",
            "App: \(appVersion) (\(build))",
            "macOS: \(osVersion)",
            "Architecture: \(architecture)",
            "Locale: \(localeIdentifier)",
            "App location: \(appLocation.rawValue)",
            "Codex source: \(codexSource.rawValue)",
            "Connection: \(connectionState)",
            "Launch at login: \(launchAtLogin)",
            "Automatic update checks: \(automaticUpdates ? "On" : "Off")",
            "Usage notifications: \(notifications ? "On" : "Off")",
            "Notification permission: \(notificationAuthorization.rawValue)"
        ].joined(separator: "\n")
    }

    private static var currentArchitecture: String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }
}

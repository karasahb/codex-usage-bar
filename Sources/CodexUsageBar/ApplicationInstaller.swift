import AppKit
import Foundation

enum ApplicationInstallState: Equatable {
    case idle
    case copying
}

@MainActor
final class ApplicationInstaller: ObservableObject {
    static let enableLaunchAtLoginEnvironmentKey = "CODEX_USAGE_BAR_ENABLE_LAUNCH_AT_LOGIN"

    @Published private(set) var state: ApplicationInstallState = .idle
    @Published private(set) var errorMessage: String?

    var canInstallCurrentApp: Bool {
        Bundle.main.bundleURL.pathExtension.lowercased() == "app"
            && !ApplicationLocation.isInApplicationsDirectory()
    }

    func copyToApplicationsAndRelaunch() {
        guard canInstallCurrentApp, state == .idle else { return }
        errorMessage = nil
        state = .copying

        let source = Bundle.main.bundleURL.standardizedFileURL
        let applicationsDirectory = FileManager.default.urls(
            for: .applicationDirectory,
            in: .localDomainMask
        ).first ?? URL(fileURLWithPath: "/Applications", isDirectory: true)
        let destination = applicationsDirectory.appendingPathComponent(
            source.lastPathComponent,
            isDirectory: true
        )

        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                throw ApplicationInstallError.destinationExists
            }
            try FileManager.default.copyItem(at: source, to: destination)
        } catch {
            state = .idle
            errorMessage = localizedInstallError(error)
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        configuration.environment = [Self.enableLaunchAtLoginEnvironmentKey: "1"]
        NSWorkspace.shared.openApplication(at: destination, configuration: configuration) {
            [weak self] runningApplication, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error {
                    self.state = .idle
                    self.errorMessage = self.localizedInstallError(error)
                } else if runningApplication != nil {
                    NSApplication.shared.terminate(nil)
                } else {
                    self.state = .idle
                    self.errorMessage = L10n.string(
                        "startup.install_failed_unknown",
                        fallback: "The copied app could not be opened."
                    )
                }
            }
        }
    }

    private func localizedInstallError(_ error: Error) -> String {
        if case ApplicationInstallError.destinationExists = error {
            return L10n.string(
                "startup.destination_exists",
                fallback: "Codex Usage Bar already exists in Applications. Open or remove that copy first."
            )
        }
        return L10n.format(
            "startup.install_failed",
            fallback: "Could not copy the app to Applications: %@",
            error.localizedDescription
        )
    }
}

private enum ApplicationInstallError: Error {
    case destinationExists
}

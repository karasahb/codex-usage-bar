import Combine
import ServiceManagement

enum LaunchAtLoginState: Equatable {
    case disabled
    case enabled
    case requiresApproval
    case unavailable

    init(serviceStatus: SMAppService.Status) {
        switch serviceStatus {
        case .notRegistered:
            self = .disabled
        case .enabled:
            self = .enabled
        case .requiresApproval:
            self = .requiresApproval
        case .notFound:
            self = .unavailable
        @unknown default:
            self = .unavailable
        }
    }

    var isSelected: Bool {
        self == .enabled || self == .requiresApproval
    }
}

@MainActor
final class LaunchAtLoginManager: ObservableObject {
    @Published private(set) var state: LaunchAtLoginState
    @Published private(set) var errorMessage: String?

    private let service: SMAppService

    init(service: SMAppService = .mainApp) {
        self.service = service
        state = LaunchAtLoginState(serviceStatus: service.status)
    }

    func refresh() {
        state = LaunchAtLoginState(serviceStatus: service.status)
        errorMessage = nil
    }

    func setEnabled(_ enabled: Bool) {
        errorMessage = nil

        do {
            if enabled {
                switch service.status {
                case .notRegistered:
                    try service.register()
                case .enabled, .requiresApproval:
                    break
                case .notFound:
                    break
                @unknown default:
                    break
                }
            } else {
                switch service.status {
                case .enabled, .requiresApproval:
                    try service.unregister()
                case .notRegistered, .notFound:
                    break
                @unknown default:
                    break
                }
            }
        } catch {
            state = LaunchAtLoginState(serviceStatus: service.status)
            errorMessage = L10n.format(
                "startup.change_failed",
                fallback: "Could not change launch at login: %@",
                error.localizedDescription
            )
            return
        }

        refresh()
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}

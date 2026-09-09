import Combine
import Foundation
import UserNotifications

enum NotificationAuthorizationState: String, Equatable {
    case unknown
    case authorized
    case denied
}

enum UsageLimitKind: String, CaseIterable {
    case fiveHour
    case weekly
}

struct UsageThresholdCrossing: Equatable {
    static let threshold = 25

    static func crossed(previous: Int?, current: Int?) -> Bool {
        guard let previous, let current else { return false }
        return previous >= threshold && current < threshold
    }
}

@MainActor
final class UsageNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published private(set) var authorizationState: NotificationAuthorizationState = .unknown
    @Published private(set) var errorMessage: String?

    private let settings: AppSettings
    private let store: UsageStore
    private let center: UNUserNotificationCenter
    private var previousValues: [UsageLimitKind: Int] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var isStarted = false

    init(
        settings: AppSettings,
        store: UsageStore,
        center: UNUserNotificationCenter = .current()
    ) {
        self.settings = settings
        self.store = store
        self.center = center
        super.init()
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true
        center.delegate = self
        refreshAuthorization()

        store.$snapshot
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] snapshot in self?.consume(snapshot) }
            .store(in: &cancellables)

        settings.$notificationsEnabled
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] enabled in
                guard let self else { return }
                if enabled {
                    self.requestAuthorization()
                } else {
                    self.errorMessage = nil
                    self.refreshAuthorization()
                }
            }
            .store(in: &cancellables)

        if settings.notificationsEnabled {
            requestAuthorization()
        }
    }

    func stop() {
        isStarted = false
        cancellables.removeAll()
    }

    func requestAuthorization() {
        errorMessage = nil
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error {
                    self.errorMessage = error.localizedDescription
                }
                self.authorizationState = granted ? .authorized : .denied
            }
        }
    }

    func refreshAuthorization() {
        center.getNotificationSettings { [weak self] notificationSettings in
            DispatchQueue.main.async {
                self?.authorizationState = Self.map(notificationSettings.authorizationStatus)
            }
        }
    }

    private func consume(_ snapshot: UsageDisplaySnapshot) {
        let current: [UsageLimitKind: Int?] = [
            .fiveHour: snapshot.fiveHour?.remainingPercent,
            .weekly: snapshot.weekly?.remainingPercent
        ]

        for kind in UsageLimitKind.allCases {
            let value = current[kind] ?? nil
            if settings.notificationsEnabled,
               authorizationState == .authorized,
               UsageThresholdCrossing.crossed(previous: previousValues[kind], current: value),
               let value {
                deliverNotification(for: kind, remainingPercent: value)
            }
            if let value {
                previousValues[kind] = value
            } else {
                previousValues.removeValue(forKey: kind)
            }
        }
    }

    private func deliverNotification(for kind: UsageLimitKind, remainingPercent: Int) {
        let windowName: String
        switch kind {
        case .fiveHour:
            windowName = L10n.string("usage.five_hour", fallback: "5-hour")
        case .weekly:
            windowName = L10n.string("usage.weekly", fallback: "Weekly")
        }

        let content = UNMutableNotificationContent()
        content.title = L10n.string("notification.title", fallback: "Codex usage is running low")
        content.body = L10n.format(
            "notification.body",
            fallback: "%@ remaining usage is now %%%d.",
            windowName,
            remainingPercent
        )
        content.sound = .default

        center.add(
            UNNotificationRequest(
                identifier: "usage-\(kind.rawValue)-\(UUID().uuidString)",
                content: content,
                trigger: nil
            )
        ) { [weak self] error in
            guard let error else { return }
            DispatchQueue.main.async { self?.errorMessage = error.localizedDescription }
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    private static func map(_ status: UNAuthorizationStatus) -> NotificationAuthorizationState {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
}

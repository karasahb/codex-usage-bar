import Combine
import Foundation

@MainActor
final class UsageStore: ObservableObject {
    @Published private(set) var snapshot: UsageDisplaySnapshot?
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String?

    private let settings: AppSettings
    private var client: CodexAppServerClient
    private var timer: Timer?
    private var isStarted = false
    private var settingsObservers = Set<AnyCancellable>()

    init(settings: AppSettings) {
        self.settings = settings
        client = CodexAppServerClient(configuredExecutablePath: settings.normalizedCodexExecutablePath)

        settings.$codexExecutablePath
            .dropFirst()
            .removeDuplicates()
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor in self?.reconnect() }
            }
            .store(in: &settingsObservers)

        settings.$refreshInterval
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                Task { @MainActor in self?.scheduleTimer() }
            }
            .store(in: &settingsObservers)
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true
        isRefreshing = true
        connectClient()
        scheduleTimer()
    }

    private func connectClient() {
        client.start(
            onSnapshot: { [weak self] response in
                DispatchQueue.main.async {
                    self?.snapshot = UsageDisplaySnapshot(response: response)
                    self?.errorMessage = nil
                    self?.isRefreshing = false
                }
            },
            onError: { [weak self] error in
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                    self?.isRefreshing = false
                }
            }
        )

    }

    private func scheduleTimer() {
        guard isStarted else { return }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: settings.refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        timer?.tolerance = 1
    }

    func refresh() {
        isRefreshing = true
        client.refresh()
    }

    func reconnect() {
        client.stop()
        client = CodexAppServerClient(configuredExecutablePath: settings.normalizedCodexExecutablePath)
        errorMessage = nil
        guard isStarted else { return }
        isRefreshing = true
        connectClient()
        scheduleTimer()
    }

    func stop() {
        isStarted = false
        timer?.invalidate()
        timer = nil
        client.stop()
    }
}

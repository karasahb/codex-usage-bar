import Combine
import Foundation

struct AppVersion: Comparable, Equatable {
    private let components: [Int]

    init?(_ value: String) {
        var cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.lowercased().hasPrefix("v") {
            cleaned.removeFirst()
        }
        let normalized = cleaned
            .split(separator: "-", maxSplits: 1)
            .first ?? ""
        let parsed = normalized.split(separator: ".").compactMap { Int($0) }
        guard !parsed.isEmpty, parsed.count == normalized.split(separator: ".").count else {
            return nil
        }
        components = parsed
    }

    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0..<count {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right { return left < right }
        }
        return false
    }

    static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        !(lhs < rhs) && !(rhs < lhs)
    }
}

enum UpdateState: Equatable {
    case idle
    case checking
    case current
    case available(version: String, url: URL)
    case failed(String)
}

@MainActor
final class UpdateChecker: ObservableObject {
    @Published private(set) var state: UpdateState = .idle

    private static let endpoint = URL(
        string: "https://api.github.com/repos/karasahb/codex-usage-bar/releases/latest"
    )!
    private static let interval: TimeInterval = 6 * 60 * 60

    private let settings: AppSettings
    private let currentVersion: String
    private let session: URLSession
    private var timer: Timer?
    private var requestTask: Task<Void, Never>?
    private var isStarted = false
    private var settingsObservers = Set<AnyCancellable>()

    init(
        settings: AppSettings,
        currentVersion: String = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "0.0.0",
        session: URLSession = .shared
    ) {
        self.settings = settings
        self.currentVersion = currentVersion
        self.session = session

        settings.$automaticUpdateChecks
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                Task { @MainActor in self?.scheduleAutomaticChecks() }
            }
            .store(in: &settingsObservers)
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true
        scheduleAutomaticChecks()
    }

    private func scheduleAutomaticChecks() {
        guard isStarted else { return }
        timer?.invalidate()
        timer = nil

        guard settings.automaticUpdateChecks else { return }
        check()
        timer = Timer.scheduledTimer(withTimeInterval: Self.interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.check() }
        }
        timer?.tolerance = 15 * 60
    }

    func stop() {
        isStarted = false
        timer?.invalidate()
        timer = nil
        requestTask?.cancel()
        requestTask = nil
    }

    func check() {
        guard state != .checking else { return }
        state = .checking
        requestTask?.cancel()
        requestTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                var request = URLRequest(url: Self.endpoint)
                request.timeoutInterval = 15
                request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
                request.setValue("2026-03-10", forHTTPHeaderField: "X-GitHub-Api-Version")
                request.setValue("CodexUsageBar/\(currentVersion)", forHTTPHeaderField: "User-Agent")

                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200..<300).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }

                let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                guard let installed = AppVersion(currentVersion),
                      let latest = AppVersion(release.tagName) else {
                    throw UpdateCheckError.invalidVersion
                }

                state = latest > installed
                    ? .available(version: release.tagName.removingLeadingV, url: release.htmlURL)
                    : .current
            } catch is CancellationError {
                return
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }
}

private extension String {
    var removingLeadingV: String {
        lowercased().hasPrefix("v") ? String(dropFirst()) : self
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}

private enum UpdateCheckError: LocalizedError {
    case invalidVersion

    var errorDescription: String? {
        L10n.string(
            "error.invalid_release_version",
            fallback: "The release version could not be read."
        )
    }
}

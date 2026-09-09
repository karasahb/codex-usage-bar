import Foundation

enum ApplicationLocationCategory: String {
    case applications
    case other
}

enum ApplicationLocation {
    static func category(
        for bundleURL: URL = Bundle.main.bundleURL,
        applicationDirectories: [URL] = FileManager.default.urls(
            for: .applicationDirectory,
            in: [.localDomainMask, .userDomainMask, .systemDomainMask]
        )
    ) -> ApplicationLocationCategory {
        isInApplicationsDirectory(bundleURL, applicationDirectories: applicationDirectories)
            ? .applications
            : .other
    }

    static func isInApplicationsDirectory(
        _ bundleURL: URL = Bundle.main.bundleURL,
        applicationDirectories: [URL] = FileManager.default.urls(
            for: .applicationDirectory,
            in: [.localDomainMask, .userDomainMask, .systemDomainMask]
        )
    ) -> Bool {
        let candidate = bundleURL.standardizedFileURL.path
        return applicationDirectories.contains { directory in
            let root = directory.standardizedFileURL.path
            return candidate == root || candidate.hasPrefix(root + "/")
        }
    }
}

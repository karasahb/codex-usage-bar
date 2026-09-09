import Foundation

enum AppServerClientError: LocalizedError {
    case executableNotFound
    case invalidConfiguredPath
    case processStopped(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .executableNotFound:
            return L10n.string(
                "error.codex_not_found",
                fallback: "Codex was not found. Make sure ChatGPT/Codex is installed."
            )
        case .invalidConfiguredPath:
            return L10n.string(
                "error.invalid_codex_path",
                fallback: "The Codex path in Settings is not a valid executable."
            )
        case .processStopped(let message):
            return message.isEmpty
                ? L10n.string("error.connection_closed", fallback: "The Codex connection closed.")
                : message
        case .invalidResponse:
            return L10n.string(
                "error.invalid_usage_response",
                fallback: "Codex returned an invalid usage response."
            )
        }
    }
}

final class CodexAppServerClient {
    typealias SnapshotHandler = (RateLimitsResponse) -> Void
    typealias ErrorHandler = (Error) -> Void

    private let queue = DispatchQueue(label: "com.codexusagebar.app-server")
    private var process: Process?
    private var input: Pipe?
    private var output: Pipe?
    private var outputBuffer = Data()
    private var nextRequestID = 1
    private var initializeRequestID: Int?
    private var rateLimitRequestIDs = Set<Int>()
    private var isInitialized = false
    private var isStopping = false
    private var snapshotHandler: SnapshotHandler?
    private var errorHandler: ErrorHandler?
    private let configuredExecutablePath: String?

    init(configuredExecutablePath: String? = nil) {
        self.configuredExecutablePath = configuredExecutablePath
    }

    func start(onSnapshot: @escaping SnapshotHandler, onError: @escaping ErrorHandler) {
        queue.async { [weak self] in
            guard let self else { return }
            self.snapshotHandler = onSnapshot
            self.errorHandler = onError
            self.launchIfNeeded()
        }
    }

    func refresh() {
        queue.async { [weak self] in
            guard let self else { return }
            if self.process?.isRunning != true {
                self.launchIfNeeded()
                return
            }
            guard self.isInitialized else { return }
            self.sendRateLimitsRead()
        }
    }

    func stop() {
        queue.sync {
            isStopping = true
            output?.fileHandleForReading.readabilityHandler = nil
            input?.fileHandleForWriting.closeFile()
            if process?.isRunning == true {
                process?.terminate()
            }
            resetProcessState()
        }
    }

    private func launchIfNeeded() {
        guard process?.isRunning != true else { return }
        let executable: URL
        if let configuredExecutablePath {
            guard let configured = Self.resolveConfiguredExecutable(configuredExecutablePath) else {
                errorHandler?(AppServerClientError.invalidConfiguredPath)
                return
            }
            executable = configured
        } else {
            guard let detected = Self.autoDetectedExecutable() else {
                errorHandler?(AppServerClientError.executableNotFound)
                return
            }
            executable = detected
        }

        let process = Process()
        let input = Pipe()
        let output = Pipe()
        process.executableURL = executable
        process.arguments = ["app-server", "--stdio"]
        process.standardInput = input
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice

        output.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            self?.queue.async { self?.consumeOutput(data) }
        }
        process.terminationHandler = { [weak self] _ in
            self?.queue.async { self?.handleTermination() }
        }

        do {
            try process.run()
            self.process = process
            self.input = input
            self.output = output
            outputBuffer.removeAll(keepingCapacity: true)
            isInitialized = false
            isStopping = false
            sendInitialize()
        } catch {
            resetProcessState()
            errorHandler?(error)
        }
    }

    private func sendInitialize() {
        let id = allocateRequestID()
        initializeRequestID = id
        send([
            "id": id,
            "method": "initialize",
            "params": [
                "clientInfo": [
                    "name": "codex_usage_bar",
                    "title": "Codex Usage Bar",
                    "version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development"
                ],
                "capabilities": [
                    "experimentalApi": false,
                    "optOutNotificationMethods": []
                ]
            ]
        ])
    }

    private func finishInitialization() {
        guard !isInitialized else { return }
        isInitialized = true
        send(["method": "initialized"])
        sendRateLimitsRead()
    }

    private func sendRateLimitsRead() {
        guard rateLimitRequestIDs.isEmpty else { return }
        let id = allocateRequestID()
        rateLimitRequestIDs.insert(id)
        send([
            "id": id,
            "method": "account/rateLimits/read",
            "params": NSNull()
        ])
    }

    private func allocateRequestID() -> Int {
        defer { nextRequestID += 1 }
        return nextRequestID
    }

    private func send(_ object: [String: Any]) {
        guard JSONSerialization.isValidJSONObject(object),
              var data = try? JSONSerialization.data(withJSONObject: object) else { return }
        data.append(0x0A)
        do {
            try input?.fileHandleForWriting.write(contentsOf: data)
        } catch {
            errorHandler?(error)
        }
    }

    private func consumeOutput(_ data: Data) {
        outputBuffer.append(data)
        while let newline = outputBuffer.firstIndex(of: 0x0A) {
            let line = outputBuffer[..<newline]
            outputBuffer.removeSubrange(...newline)
            guard !line.isEmpty else { continue }
            handleLine(Data(line))
        }
    }

    private func handleLine(_ line: Data) {
        guard let header = try? JSONDecoder().decode(RPCHeader.self, from: line) else {
            return
        }

        if let id = header.id, id == initializeRequestID {
            initializeRequestID = nil
            if header.error != nil {
                errorHandler?(AppServerClientError.invalidResponse)
            } else {
                finishInitialization()
            }
            return
        }

        if let id = header.id, rateLimitRequestIDs.remove(id) != nil {
            guard header.error == nil,
                  let envelope = try? JSONDecoder().decode(RateLimitsRPCResponse.self, from: line),
                  let response = envelope.result else {
                errorHandler?(AppServerClientError.invalidResponse)
                return
            }
            snapshotHandler?(response)
            return
        }

        if header.method == "account/rateLimits/updated" {
            sendRateLimitsRead()
        }
    }

    private func handleTermination() {
        resetProcessState()
        guard !isStopping else { return }
        errorHandler?(
            AppServerClientError.processStopped(
                L10n.string(
                    "error.connection_reconnecting",
                    fallback: "The Codex connection closed; reconnecting."
                )
            )
        )
    }

    private func resetProcessState() {
        output?.fileHandleForReading.readabilityHandler = nil
        process = nil
        input = nil
        output = nil
        isInitialized = false
        initializeRequestID = nil
        rateLimitRequestIDs.removeAll()
    }

    static func autoDetectedExecutable() -> URL? {
        let environment = ProcessInfo.processInfo.environment
        var candidates = [String]()
        if let override = environment["CODEX_USAGE_BAR_CODEX_PATH"], !override.isEmpty {
            candidates.append(override)
        }
        candidates += [
            "/Applications/ChatGPT.app/Contents/Resources/codex",
            "/Applications/Codex.app/Contents/Resources/codex",
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex"
        ]

        if let path = environment["PATH"] {
            candidates += path.split(separator: ":").map { "\($0)/codex" }
        }

        return candidates
            .map { URL(fileURLWithPath: $0) }
            .first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }

    static func resolveConfiguredExecutable(_ path: String) -> URL? {
        let selected = URL(fileURLWithPath: path)
        let candidates: [URL]
        if selected.pathExtension.lowercased() == "app" {
            candidates = [
                selected.appendingPathComponent("Contents/Resources/codex"),
                selected.appendingPathComponent("Contents/MacOS/codex")
            ]
        } else {
            candidates = [selected]
        }

        return candidates.first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }
}

private struct RPCHeader: Decodable {
    let id: Int?
    let method: String?
    let error: RPCError?
}

private struct RateLimitsRPCResponse: Decodable {
    let result: RateLimitsResponse?
}

private struct RPCError: Decodable {}

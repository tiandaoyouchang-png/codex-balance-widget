import Foundation

final class CodexUsageService: @unchecked Sendable {
    func fetch() async throws -> SharedUsageSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(with: Result { try self.fetchSynchronously() })
            }
        }
    }

    private func fetchSynchronously() throws -> SharedUsageSnapshot {
        guard let executable = codexExecutable() else { throw UsageFetchError.codexNotFound }

        let process = Process()
        let input = Pipe()
        let output = Pipe()
        process.executableURL = executable
        process.arguments = ["app-server", "--stdio"]
        process.standardInput = input
        process.standardOutput = output
        process.standardError = Pipe()

        let signal = DispatchSemaphore(value: 0)
        let lock = NSLock()
        var buffer = Data()
        var response: Result<SharedUsageSnapshot, Error>?

        func finish(_ result: Result<SharedUsageSnapshot, Error>) {
            lock.lock()
            guard response == nil else { lock.unlock(); return }
            response = result
            lock.unlock()
            signal.signal()
        }

        output.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }

            lock.lock()
            buffer.append(data)
            var lines: [Data] = []
            while let newline = buffer.firstIndex(of: 0x0A) {
                lines.append(buffer.prefix(upTo: newline))
                buffer.removeSubrange(...newline)
            }
            lock.unlock()

            for line in lines {
                guard
                    let object = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
                    (object["id"] as? NSNumber)?.intValue == 2
                else { continue }
                do {
                    finish(.success(try self.parse(object)))
                } catch {
                    finish(.failure(error))
                }
            }
        }

        do { try process.run() } catch {
            output.fileHandleForReading.readabilityHandler = nil
            throw UsageFetchError.launchFailed(error.localizedDescription)
        }

        let messages: [[String: Any]] = [
            ["id": 1, "method": "initialize", "params": [
                "clientInfo": ["name": "codex-balance-widget", "version": "1.0.0"],
                "capabilities": ["experimentalApi": true]
            ]],
            ["method": "initialized"],
            ["id": 2, "method": "account/rateLimits/read", "params": NSNull()]
        ]
        for message in messages {
            input.fileHandleForWriting.write(try JSONSerialization.data(withJSONObject: message))
            input.fileHandleForWriting.write(Data([0x0A]))
        }

        if signal.wait(timeout: .now() + 20) == .timedOut {
            finish(.failure(UsageFetchError.timedOut))
        }
        output.fileHandleForReading.readabilityHandler = nil
        try? input.fileHandleForWriting.close()
        if process.isRunning { process.terminate() }

        lock.lock()
        let result = response ?? .failure(UsageFetchError.invalidResponse)
        lock.unlock()
        return try result.get()
    }

    private func parse(_ object: [String: Any]) throws -> SharedUsageSnapshot {
        if let error = object["error"] as? [String: Any] {
            throw UsageFetchError.server(error["message"] as? String ?? "未知错误")
        }
        guard let result = object["result"] as? [String: Any] else {
            throw UsageFetchError.invalidResponse
        }
        let byID = result["rateLimitsByLimitId"] as? [String: Any]
        guard let snapshot = (byID?["codex"] as? [String: Any])
            ?? (result["rateLimits"] as? [String: Any]) else {
            throw UsageFetchError.invalidResponse
        }

        let windows = [snapshot["primary"], snapshot["secondary"]]
            .compactMap { $0 as? [String: Any] }
            .compactMap { window -> SharedUsageWindow? in
                guard let used = (window["usedPercent"] as? NSNumber)?.intValue else { return nil }
                let duration = (window["windowDurationMins"] as? NSNumber)?.intValue
                let reset = (window["resetsAt"] as? NSNumber)?.doubleValue
                return SharedUsageWindow(
                    usedPercent: used,
                    durationMinutes: duration,
                    resetsAt: reset.map(Date.init(timeIntervalSince1970:))
                )
            }
        guard !windows.isEmpty else { throw UsageFetchError.invalidResponse }

        let resetSummary = result["rateLimitResetCredits"] as? [String: Any]
        return SharedUsageSnapshot(
            plan: snapshot["planType"] as? String ?? "unknown",
            windows: windows,
            resetCredits: (resetSummary?["availableCount"] as? NSNumber)?.intValue ?? 0,
            updatedAt: Date()
        )
    }

    private func codexExecutable() -> URL? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let paths = [
            "/Applications/ChatGPT.app/Contents/Resources/codex",
            "/Applications/Codex.app/Contents/Resources/codex",
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex",
            "\(home)/.hermes/node/bin/codex"
        ]
        return paths.first(where: FileManager.default.isExecutableFile(atPath:)).map(URL.init(fileURLWithPath:))
    }
}

enum UsageFetchError: LocalizedError {
    case codexNotFound
    case launchFailed(String)
    case timedOut
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .codexNotFound: return "没有找到本机 Codex。"
        case .launchFailed(let message): return "无法启动 Codex：\(message)"
        case .timedOut: return "读取超时，请检查网络和登录状态。"
        case .invalidResponse: return "Codex 返回了无法识别的额度数据。"
        case .server(let message): return "Codex 暂时无法返回额度：\(message)"
        }
    }
}

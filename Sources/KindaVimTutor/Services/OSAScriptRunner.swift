import Foundation

/// Runs an AppleScript via `/usr/bin/osascript` in a child process
/// with a hard timeout. Exists because `NSAppleScript.executeAndReturnError`
/// runs synchronously on the main thread — we discovered the hard way
/// during the Finder prototype that a slow Finder pins the whole UI
/// for tens of seconds. Out-of-process with a kill-timeout gives us
/// cancellation and keeps the main thread free no matter how slow
/// the target app is.
enum OSAScriptRunner {
    /// Run `source` and return stdout. Throws
    /// `ExternalTextSurfaceError.scriptingTimedOut` if the process
    /// doesn't finish within `timeout` seconds,
    /// `ExternalTextSurfaceError.scriptingFailed` on non-zero exit.
    static func run(_ source: String, timeout: TimeInterval = 5.0) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", source]

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            do {
                try process.run()
            } catch {
                continuation.resume(
                    throwing: ExternalTextSurfaceError.scriptingFailed(
                        "failed to launch osascript: \(error)"
                    )
                )
                return
            }

            // Arm the watchdog on a background queue. If the process
            // outlives the timeout, kill it — the waitUntilExit
            // below then returns immediately.
            let resumed = Atomic(false)
            DispatchQueue.global(qos: .utility).asyncAfter(
                deadline: .now() + timeout
            ) {
                guard !resumed.value, process.isRunning else { return }
                process.terminate()
                if resumed.swap(true) == false {
                    continuation.resume(
                        throwing: ExternalTextSurfaceError.scriptingTimedOut
                    )
                }
            }

            // Also on a background queue — waitUntilExit blocks.
            DispatchQueue.global(qos: .utility).async {
                process.waitUntilExit()
                guard resumed.swap(true) == false else { return }
                let outData = stdout.fileHandleForReading.readDataToEndOfFile()
                let errData = stderr.fileHandleForReading.readDataToEndOfFile()
                let outString = String(data: outData, encoding: .utf8) ?? ""
                let errString = String(data: errData, encoding: .utf8) ?? ""
                if process.terminationStatus == 0 {
                    continuation.resume(
                        returning: outString.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                } else {
                    continuation.resume(
                        throwing: ExternalTextSurfaceError.scriptingFailed(
                            errString.isEmpty ? outString : errString
                        )
                    )
                }
            }
        }
    }
}

/// Tiny atomic-boolean helper for the watchdog coordination. We
/// use it instead of an actor to avoid an async hop inside the
/// tight watchdog path.
private final class Atomic: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Bool
    init(_ value: Bool) { self._value = value }
    var value: Bool {
        lock.lock(); defer { lock.unlock() }
        return _value
    }
    /// Set to `new`; return the previous value.
    @discardableResult
    func swap(_ new: Bool) -> Bool {
        lock.lock(); defer { lock.unlock() }
        let old = _value
        _value = new
        return old
    }
}

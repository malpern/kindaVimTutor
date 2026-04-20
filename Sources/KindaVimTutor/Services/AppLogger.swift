import Foundation

/// File-based logger. Writes newline-delimited JSON (JSONL) and a human-readable
/// `.log` next to it, both under `~/Library/Logs/KindaVimTutor/`.
///
/// Design goals:
/// - Easy to read from a shell (plain text under a stable path).
/// - Safe to share across threads (serial queue + atomic append).
/// - Small, structured fields so automated harnesses can grep for events.
/// `@unchecked Sendable` rationale: all mutable state — the file
/// descriptors in `jsonlURL` / `textURL` and any write buffering
/// — is serialized through the private `queue`. The encoder, ISO
/// formatter, and URLs are initialized once and never replaced,
/// and Foundation's JSONEncoder / ISO8601DateFormatter are
/// documented as safe to call from multiple threads as long as
/// nobody mutates their properties (we don't after init).
final class AppLogger: @unchecked Sendable {
    enum Level: String, Codable, Sendable {
        case debug, info, warn, error
    }

    struct Entry: Codable, Sendable {
        let timestamp: String
        let level: String
        let category: String
        let message: String
        let fields: [String: String]
    }

    static let shared = AppLogger()

    private let queue = DispatchQueue(label: "kindaVimTutor.AppLogger", qos: .utility)
    private let encoder: JSONEncoder
    private let isoFormatter: ISO8601DateFormatter
    private let logsDirectory: URL
    private let jsonlURL: URL
    private let textURL: URL

    private init() {
        encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Prefer an env-override (tests/harness) so we can redirect logs without a global side effect.
        if let override = ProcessInfo.processInfo.environment["KINDAVIMTUTOR_LOG_DIR"], !override.isEmpty {
            logsDirectory = URL(fileURLWithPath: override, isDirectory: true)
        } else {
            let base = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
            logsDirectory = base.appendingPathComponent("Logs/KindaVimTutor", isDirectory: true)
        }
        jsonlURL = logsDirectory.appendingPathComponent("app.jsonl")
        textURL = logsDirectory.appendingPathComponent("app.log")

        try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
    }

    var logFileURL: URL { textURL }
    var jsonLogFileURL: URL { jsonlURL }
    var logDirectoryURL: URL { logsDirectory }

    func log(_ level: Level,
             _ category: String,
             _ message: String,
             fields: [String: String] = [:]) {
        let timestamp = isoFormatter.string(from: Date())
        let entry = Entry(timestamp: timestamp,
                          level: level.rawValue,
                          category: category,
                          message: message,
                          fields: fields)
        queue.async { [self] in
            appendJSONL(entry)
            appendText(entry)
        }
    }

    func debug(_ category: String, _ message: String, fields: [String: String] = [:]) {
        log(.debug, category, message, fields: fields)
    }
    func info(_ category: String, _ message: String, fields: [String: String] = [:]) {
        log(.info, category, message, fields: fields)
    }
    func warn(_ category: String, _ message: String, fields: [String: String] = [:]) {
        log(.warn, category, message, fields: fields)
    }
    func error(_ category: String, _ message: String, fields: [String: String] = [:]) {
        log(.error, category, message, fields: fields)
    }

    /// Blocks until queued writes finish. Used by tests so assertions see fresh content.
    func flush() {
        queue.sync { }
    }

    /// Removes both log files. Intended for tests and the harness.
    func reset() {
        queue.sync {
            try? FileManager.default.removeItem(at: jsonlURL)
            try? FileManager.default.removeItem(at: textURL)
        }
    }

    private func appendJSONL(_ entry: Entry) {
        guard let data = try? encoder.encode(entry) else { return }
        var payload = data
        payload.append(0x0A) // newline
        appendToFile(payload, url: jsonlURL)
    }

    private func appendText(_ entry: Entry) {
        var line = "[\(entry.timestamp)] \(entry.level.uppercased()) \(entry.category): \(entry.message)"
        if !entry.fields.isEmpty {
            let pairs = entry.fields.keys.sorted().map { "\($0)=\(entry.fields[$0] ?? "")" }
            line += " {" + pairs.joined(separator: " ") + "}"
        }
        line += "\n"
        guard let data = line.data(using: .utf8) else { return }
        appendToFile(data, url: textURL)
    }

    private func appendToFile(_ data: Data, url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            if let handle = try? FileHandle(forWritingTo: url) {
                defer { try? handle.close() }
                do {
                    try handle.seekToEnd()
                    try handle.write(contentsOf: data)
                } catch {
                    // Fall through to rewrite below on any seek/write error.
                }
            }
        } else {
            try? data.write(to: url, options: .atomic)
        }
    }
}

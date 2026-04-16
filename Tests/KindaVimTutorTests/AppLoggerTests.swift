import Testing
import Foundation
@testable import KindaVimTutor

@Suite("AppLogger file output", .serialized)
struct AppLoggerTests {
    @Test("log lines land in both the text and JSONL files")
    func writesToDisk() throws {
        let logger = AppLogger.shared
        // Use a unique category so we don't collide with other tests that may run in parallel.
        let cat = "test.logger.\(UUID().uuidString.prefix(6))"

        logger.info(cat, "hello", fields: ["k": "v"])
        logger.warn(cat, "careful")
        logger.flush()

        let text = try String(contentsOf: logger.logFileURL, encoding: .utf8)
        #expect(text.contains("INFO \(cat): hello"))
        #expect(text.contains("k=v"))
        #expect(text.contains("WARN \(cat): careful"))

        let jsonl = try String(contentsOf: logger.jsonLogFileURL, encoding: .utf8)
        let decoder = JSONDecoder()
        let entries = jsonl.split(separator: "\n").compactMap { line -> AppLogger.Entry? in
            try? decoder.decode(AppLogger.Entry.self, from: Data(line.utf8))
        }
        let matches = entries.filter { $0.category == cat }
        #expect(matches.count == 2)
        let helloEntry = matches.first { $0.message == "hello" }
        #expect(helloEntry?.level == "info")
        #expect(helloEntry?.fields["k"] == "v")
    }

    @Test("log path honors KINDAVIMTUTOR_LOG_DIR override")
    func honorsLogDirEnv() {
        // The singleton reads env at init — this assertion confirms the override
        // path is in use when the test harness sets it (see TestHarness env).
        let expected = ProcessInfo.processInfo.environment["KINDAVIMTUTOR_LOG_DIR"]
        if let expected {
            #expect(AppLogger.shared.logDirectoryURL.path == expected)
        }
    }
}

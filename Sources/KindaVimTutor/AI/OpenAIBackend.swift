import Foundation

/// Streaming client for OpenAI's Chat Completions API, constrained
/// to the same answer shape we use with Apple's on-device model so
/// the chat UI can render either backend through the same
/// `VimAnswerDisplay` pipeline.
///
/// Streams chunks as they arrive; the final parse is attempted at
/// `[DONE]` so the structured `relatedCommands` / `fasterAlternative`
/// cards populate atomically. During the stream we progressively
/// surface whatever plain text has arrived so the user sees
/// something instead of a spinner.
enum OpenAIBackend {
    /// Default model — gpt-5.4 gives the best Vim answers we've
    /// measured without jumping to the premium tier.
    static let defaultModel = "gpt-5.4"

    enum BackendError: LocalizedError {
        case missingAPIKey
        case invalidAPIKey
        case rateLimited
        case httpStatus(Int, String)
        case decodeFailed(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Add your OpenAI API key in Settings → Chat AI, or set OPENAI_API_KEY in the environment."
            case .invalidAPIKey:
                return "OpenAI rejected the API key (401). Open Settings → Chat AI and update it."
            case .rateLimited:
                return "OpenAI is rate-limiting us (429). Wait a minute and try again."
            case .httpStatus(let code, let body):
                return "OpenAI request failed (\(code)). \(body.prefix(200))"
            case .decodeFailed(let raw):
                return "Couldn't parse OpenAI response. \(raw.prefix(200))"
            }
        }
    }

    /// Role of a message passed to the model. Mirrors the subset of
    /// OpenAI's chat roles we actually use.
    struct HistoryMessage {
        let role: String   // "user" or "assistant"
        let content: String
    }

    /// Snapshot yielded during streaming. Mirrors the subset of
    /// `VimAnswerDisplay` the UI updates while tokens arrive.
    struct Snapshot {
        var answer: String = ""
        var relatedCommands: [VimAnswerDisplay.RelatedCommandDisplay] = []
        var fasterAlternative: String?
        var webSearchQuery: String?
        var videoSearchQuery: String?
        var isUnsupported: Bool = false
        var terminalVimExplanation: String?
    }

    /// Stream answers for the given user query. Yields partial
    /// snapshots as text arrives; the final yielded snapshot is the
    /// complete parsed JSON when available.
    ///
    /// `history` is any prior user/assistant turns in the current
    /// chat session — passing these in gives the model conversation
    /// context so follow-up questions ("what about capital?") work.
    static func stream(
        userQuery: String,
        systemPrompt: String,
        apiKey: String,
        model: String = defaultModel,
        history: [HistoryMessage] = []
    ) -> AsyncThrowingStream<Snapshot, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await runStream(
                        userQuery: userQuery,
                        systemPrompt: systemPrompt,
                        apiKey: apiKey,
                        model: model,
                        history: history,
                        continuation: continuation
                    )
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Streaming internals

    private static func runStream(
        userQuery: String,
        systemPrompt: String,
        apiKey: String,
        model: String,
        history: [HistoryMessage],
        continuation: AsyncThrowingStream<Snapshot, Error>.Continuation
    ) async throws {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        var messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
        ]
        for turn in history {
            messages.append(["role": turn.role, "content": turn.content])
        }
        messages.append(["role": "user", "content": userQuery])

        let body: [String: Any] = [
            "model": model,
            "stream": true,
            "messages": messages,
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "VimAnswer",
                    "strict": true,
                    "schema": makeVimAnswerSchema(),
                ],
            ],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw BackendError.httpStatus(0, "no http response")
        }
        if http.statusCode != 200 {
            var errBody = ""
            for try await line in bytes.lines { errBody += line + "\n" }
            switch http.statusCode {
            case 401: throw BackendError.invalidAPIKey
            case 429: throw BackendError.rateLimited
            default:  throw BackendError.httpStatus(http.statusCode, errBody)
            }
        }

        var buffer = ""
        for try await line in bytes.lines {
            guard line.hasPrefix("data:") else { continue }
            let payload = line.dropFirst("data:".count)
                .trimmingCharacters(in: .whitespaces)
            if payload == "[DONE]" { break }

            if let data = payload.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = obj["choices"] as? [[String: Any]],
               let delta = choices.first?["delta"] as? [String: Any],
               let content = delta["content"] as? String {
                buffer += content
                let snapshot = partialSnapshot(from: buffer)
                continuation.yield(snapshot)
            }
        }

        // Final pass — parse the complete JSON buffer.
        if let final = parseFinal(buffer) {
            continuation.yield(final)
        } else if !buffer.isEmpty {
            throw BackendError.decodeFailed(buffer)
        }
    }

    // MARK: - JSON parsing

    /// Parse the complete JSON response into a full snapshot.
    private static func parseFinal(_ text: String) -> Snapshot? {
        guard let data = text.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data)
                as? [String: Any] else {
            return nil
        }
        var snap = Snapshot()
        snap.answer = (obj["answer"] as? String) ?? ""
        snap.isUnsupported = (obj["isUnsupported"] as? Bool) ?? false
        snap.fasterAlternative = obj["fasterAlternative"] as? String
        snap.webSearchQuery = obj["webSearchQuery"] as? String
        snap.videoSearchQuery = obj["videoSearchQuery"] as? String
        snap.terminalVimExplanation = obj["terminalVimExplanation"] as? String
        if let related = obj["relatedCommands"] as? [[String: Any]] {
            snap.relatedCommands = related.compactMap { entry in
                guard let command = entry["command"] as? String,
                      let summary = entry["summary"] as? String
                else { return nil }
                return .init(command: command, summary: summary)
            }
        }
        return snap
    }

    /// Best-effort progressive view of the partial JSON. While
    /// tokens are still arriving, JSON isn't parseable — but we can
    /// cheaply extract the `"answer": "..."` substring so the user
    /// sees text stream in rather than waiting for `[DONE]`.
    private static func partialSnapshot(from text: String) -> Snapshot {
        var snap = Snapshot()
        if let answer = extractStringField(named: "answer", from: text) {
            snap.answer = answer
        }
        return snap
    }

    /// Extract the live value of a top-level string field from a
    /// partial JSON buffer. Handles escaped characters naively —
    /// good enough for progressive rendering, not for final parse.
    private static func extractStringField(named name: String, from text: String) -> String? {
        guard let range = text.range(of: "\"\(name)\"") else { return nil }
        let afterKey = text[range.upperBound...]
        guard let colon = afterKey.firstIndex(of: ":") else { return nil }
        let afterColon = afterKey[afterKey.index(after: colon)...]
        guard let openQuote = afterColon.firstIndex(of: "\"") else { return nil }
        var i = afterColon.index(after: openQuote)
        var out = ""
        var escaping = false
        while i < afterColon.endIndex {
            let ch = afterColon[i]
            if escaping {
                switch ch {
                case "n": out.append("\n")
                case "t": out.append("\t")
                case "\"": out.append("\"")
                case "\\": out.append("\\")
                default: out.append(ch)
                }
                escaping = false
            } else if ch == "\\" {
                escaping = true
            } else if ch == "\"" {
                return out
            } else {
                out.append(ch)
            }
            i = afterColon.index(after: i)
        }
        // Unterminated string — still return the partial content so
        // the user sees the answer stream in.
        return out.isEmpty ? nil : out
    }

    // MARK: - JSON schema

    /// The schema handed to OpenAI for `response_format.json_schema`.
    /// Matches the field set of the `VimAnswer` Generable struct.
    /// Built as a function to avoid a concurrency-unsafe global.
    private static func makeVimAnswerSchema() -> [String: Any] { [
        "type": "object",
        "additionalProperties": false,
        "required": [
            "answer", "relatedCommands", "fasterAlternative",
            "isUnsupported", "terminalVimExplanation",
            "webSearchQuery", "videoSearchQuery",
        ],
        "properties": [
            "answer": [
                "type": "string",
                "description": "Direct 1-3 sentence answer. Use backticks for keys (e.g. `dw`) and {{mode}} for modes (e.g. {{normal}}).",
            ],
            "relatedCommands": [
                "type": "array",
                "items": [
                    "type": "object",
                    "additionalProperties": false,
                    "required": ["command", "summary"],
                    "properties": [
                        "command": ["type": "string"],
                        "summary": ["type": "string"],
                    ],
                ],
                "description": "2-4 related commands NOT mentioned in `answer`.",
            ],
            "fasterAlternative": [
                "type": ["string", "null"],
                "description": "Optional one-sentence faster way.",
            ],
            "isUnsupported": [
                "type": "boolean",
                "description": "True when the question is about a feature kindaVim does not implement.",
            ],
            "terminalVimExplanation": [
                "type": ["string", "null"],
                "description": "Only when isUnsupported is true. How it works in stock Vim.",
            ],
            "webSearchQuery": [
                "type": ["string", "null"],
                "description": "Optional web-search query for supplementary articles.",
            ],
            "videoSearchQuery": [
                "type": ["string", "null"],
                "description": "Optional YouTube query (include 'vim').",
            ],
        ],
    ] }
}

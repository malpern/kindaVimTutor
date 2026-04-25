import Foundation

/// Generates a full practice *lesson* for a chat concept — a
/// visualization (optional), teaching blocks, and a drill — so the
/// generated experience mirrors an authored curriculum lesson
/// instead of just an isolated exercise.
///
/// Design constraints (see also the notes in OpenAIBackend):
///  - The exercise remains text-only verified
///    (`expectedCursorPosition: nil`). LLMs are unreliable at
///    counting string offsets.
///  - Visualizations reuse the existing authored views
///    (`GrammarGridView`, `FindVsTillView`, `HomeRowView`, etc.)
///    via a closed enum. We never let the model emit raw SwiftUI —
///    the failure mode of a hallucinated diagram is too costly.
///  - Explanation blocks are drawn from a small, verified subset of
///    `ContentBlock` cases that we know render safely.
enum LessonGenerator {
    enum GenerationError: LocalizedError {
        case backend(Error)
        case parseFailed(String)

        var errorDescription: String? {
            switch self {
            case .backend(let e):
                return (e as? LocalizedError)?.errorDescription
                    ?? "Couldn't reach OpenAI: \(e)"
            case .parseFailed(let raw):
                return "OpenAI returned a lesson we couldn't parse. \(raw.prefix(200))"
            }
        }
    }

    /// Result of a successful generation. Rendered by
    /// `GeneratedLessonSheet` as visualization → explanation → drill.
    struct GeneratedLesson {
        let visualization: Visualization?
        let homeRowKeys: [String]
        let explanation: [ContentBlock]
        let exercise: Exercise

        /// The visualization as a render-ready ContentBlock, if any.
        var visualizationBlock: ContentBlock? {
            visualization?.contentBlock(homeRowKeys: homeRowKeys)
        }
    }

    /// Closed enum of visualizations the LLM can route to. Mapped
    /// 1:1 onto existing `ContentBlock` cases so rendering goes
    /// through the standard `ExplanationView` pipeline.
    enum Visualization: String, CaseIterable {
        case grammarGrid
        case findVsTill
        case modesDemo
        case modeIndicatorSpotlight
        case homeRow

        /// Turn the generator's choice (plus any auxiliary data like
        /// the home-row keys to highlight) into a ContentBlock.
        func contentBlock(homeRowKeys: [String]) -> ContentBlock {
            switch self {
            case .grammarGrid:            return .grammarGrid
            case .findVsTill:             return .findVsTill
            case .modesDemo:              return .modesDemo
            case .modeIndicatorSpotlight: return .modeIndicatorSpotlight
            case .homeRow:                return .homeRow(highlighted: homeRowKeys)
            }
        }
    }

    /// Ask the model for a fresh lesson. `question` is the user's
    /// original chat question. `topic` grounds the lesson in our
    /// authored reference so the generated motion set matches what
    /// kindaVim actually supports.
    static func generate(
        question: String,
        topic: HelpTopic?,
        apiKey: String,
        model: String = OpenAIBackend.defaultModel
    ) async throws -> GeneratedLesson {
        let systemPrompt = buildSystemPrompt(topic: topic)
        let userPrompt = buildUserPrompt(question: question, topic: topic)

        do {
            let json = try await postForJSON(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                apiKey: apiKey,
                model: model
            )
            guard let lesson = lesson(fromJSON: json) else {
                throw GenerationError.parseFailed(json)
            }
            return lesson
        } catch let error as GenerationError {
            throw error
        } catch {
            throw GenerationError.backend(error)
        }
    }

    // MARK: - HTTP

    private static func postForJSON(
        systemPrompt: String,
        userPrompt: String,
        apiKey: String,
        model: String
    ) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "stream": false,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt],
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "GeneratedLesson",
                    "strict": true,
                    "schema": makeSchema(),
                ],
            ],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OpenAIBackend.BackendError.httpStatus(0, "no http response")
        }
        if http.statusCode != 200 {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            switch http.statusCode {
            case 401: throw OpenAIBackend.BackendError.invalidAPIKey
            case 429: throw OpenAIBackend.BackendError.rateLimited
            default:
                throw OpenAIBackend.BackendError.httpStatus(http.statusCode, bodyText)
            }
        }
        guard let obj = try? JSONSerialization.jsonObject(with: data)
                as? [String: Any],
              let choices = obj["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String
        else {
            let raw = String(data: data, encoding: .utf8) ?? ""
            throw GenerationError.parseFailed(raw)
        }
        return content
    }

    // MARK: - Prompt

    private static func buildSystemPrompt(topic: HelpTopic?) -> String {
        var out = """
        You generate a single short practice LESSON for the kindaVim Tutor app.
        A lesson has three parts:
          1. An optional named visualization (pick at most one).
          2. 2–5 short teaching blocks (heading / text / tip / keyCommand).
          3. One interactive exercise the student types through.

        Your output is rendered with the app's authored components — pick
        the teaching primitives, don't try to invent new ones.

        ## Visualization (optional)
        `visualization` MUST be one of: "grammarGrid", "findVsTill",
        "modesDemo", "modeIndicatorSpotlight", "homeRow", or null.

        Pick one only when it genuinely aids understanding of THIS concept:
        - `grammarGrid`: for operator × motion compositionality
          (d, c, y × w, iw, $, etc.). Use for "how do verbs compose".
        - `findVsTill`: for f/F vs t/T landing behaviour.
        - `modesDemo`: for normal/insert/visual mode switching concepts.
        - `modeIndicatorSpotlight`: when anchoring "where's my mode shown?"
        - `homeRow`: for hjkl, or for any claim about keys sitting under
          the student's resting fingers. Populate `homeRowKeys` with the
          keys to highlight (lowercase letter tokens, e.g. ["h","j","k","l"]).

        Prefer null when none of the above fits — a wrong visualization
        is worse than none.

        ## Explanation blocks (2–5 items, ordered)
        Each block is an object `{ "kind": "...", ... }`. Allowed kinds:
          - `{"kind": "heading", "text": "…"}` — one short heading.
          - `{"kind": "text", "text": "…"}` — 1–3 sentence paragraph.
          - `{"kind": "tip", "text": "…"}` — a short one-liner insight.
          - `{"kind": "important", "text": "…"}` — a gotcha / caveat.
          - `{"kind": "keyCommand", "keys": ["d","w"], "description": "…"}`
              — a single key-command row. Keys are individual tokens,
              one character per cell. Short descriptions, 4–10 words.
          - `{"kind": "spacer"}` — vertical spacing.

        Style: terse, concrete, backticks around keys inside text prose.
        Use {{normal}}/{{insert}}/{{visual}} for modes inside text prose.

        ## Exercise (text-only verification — no cursor positions)
        - `instruction`: one short sentence. Use backticks for keys.
        - `initialText`: a short paragraph (6–15 lines) of plain text.
          Include a blank line or two at top and bottom. No tabs.
        - `expectedText`: EXACTLY `initialText` except for the transform
          the instruction describes. Double-check every unchanged character.
        - `hints`: 1–2 short hints with backticked keys.
        - `motionsUsed`: array of 1–3 canonical commands the drill teaches.
        - `variations`: EXACTLY 2 additional reps of the SAME transform on
          different text. Each variation is an `{ initialText, expectedText }`
          pair. Keep the motion set identical across variations — vary the
          sentence content, not the technique being drilled. The student
          will complete all 3 reps (base + 2 variations) to finish the lesson.

        ## Hard rules
        - Use ONLY motions supported by kindaVim. Supported motion set:
          hjkl, w/W/b/B/e/E, 0/^/$, gg/G, {/}/(/)/
          f/F/t/T/;/,, d/c/y/x/X/p/P (with motion/text-object),
          iw/aw/iW/aW/ib/ab/iB/aB/i"/a"/i'/a'/i[/a[/ip/ap,
          /, ?, n, N, ~, i/I/a/A/o/O/s/S/r, v/V, u, Ctrl-R, ., J.
        - Do NOT use: macros (q/@), Ex commands (:w/:q/:s), named
          registers, splits, folds, marks, gU/gu/g~ case operators,
          raw di(/di{ forms (use dib/diB).
        - Keep the exercise transformation small and deterministic
          (one word, one line, one sentence).

        ## Navigation-only motions (critical)
        A drill MUST produce a visible text change — `initialText`
        and `expectedText` MUST NOT be equal. If the concept is a
        pure navigation command (`h/j/k/l`, `w/b/e`, `0/^/$`, `gg/G`,
        `{/}`, `f/F/t/T/;/,`, `/`, `n/N`), PAIR the navigation with
        an operator so there IS a transform. Examples:
        - Teaching `;`: "use `f`x to find the first x, then `;` to
          jump to the second x, then `x` to delete it."
        - Teaching `w`: "use `w` to hop to the word 'foo', then `dw`
          to delete it."
        - Teaching `}`: "use `}` to jump to the target paragraph,
          then `dd` to delete the marked line."
        If you genuinely cannot construct a transform drill for the
        concept, emit an `exercise` with a small but real transform
        that uses the motion incidentally — never a no-op drill.
        """
        if let topic {
            out += """


            ## Topic context — ground the lesson in this reference
            Title: \(topic.title)
            Summary: \(topic.summary)
            Supported tags: \(topic.tags.joined(separator: ", "))
            """
            if topic.status == .unsupported {
                out += """

                NOTE: this topic is UNSUPPORTED in kindaVim. Respond with
                `visualization: null`, a 1-block explanation stating it
                isn't supported, and an exercise whose initialText equals
                expectedText (the student has nothing to drill).
                """
            }
        }
        return out
    }

    private static func buildUserPrompt(question: String, topic: HelpTopic?) -> String {
        var out = "Generate a single practice lesson for the student's question:\n\n"
        out += "\"" + question + "\"\n"
        if let topic {
            out += "\nGround the lesson in the \(topic.title) topic."
        }
        return out
    }

    // MARK: - JSON parse

    private static func lesson(fromJSON json: String) -> GeneratedLesson? {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data)
                as? [String: Any]
        else { return nil }

        let exercise = parseExercise(obj["exercise"] as? [String: Any])
        guard let exercise else { return nil }

        let homeRowKeys = (obj["homeRowKeys"] as? [String]) ?? []
        let visualization: Visualization? = {
            guard let raw = obj["visualization"] as? String,
                  !raw.isEmpty,
                  raw != "null"
            else { return nil }
            return Visualization(rawValue: raw)
        }()

        let explanation = parseExplanation(obj["explanation"] as? [[String: Any]] ?? [])

        return GeneratedLesson(
            visualization: visualization,
            homeRowKeys: homeRowKeys,
            explanation: explanation,
            exercise: exercise
        )
    }

    private static func parseExercise(_ obj: [String: Any]?) -> Exercise? {
        guard let obj,
              let instruction = obj["instruction"] as? String,
              let initialText = obj["initialText"] as? String,
              let expectedText = obj["expectedText"] as? String
        else { return nil }
        // A base with `initialText == expectedText` is a no-op drill
        // — ExerciseEngine would mark rep 0 instantly complete at
        // zero keystrokes, faking success. Reject it so the sheet
        // surfaces a failure card + Regenerate instead of
        // celebrating a drill the student never did.
        guard initialText != expectedText else { return nil }
        let hints = (obj["hints"] as? [String]) ?? []
        // Parse the 2 additional variations. Drop any that are
        // structurally broken (missing fields) or no-op (initial
        // equals expected) — a no-op rep would block completion
        // since the student has nothing to type.
        let variationRaw = (obj["variations"] as? [[String: Any]]) ?? []
        let variations: [Exercise.Variation] = variationRaw.compactMap { v in
            guard let it = v["initialText"] as? String,
                  let et = v["expectedText"] as? String,
                  it != et
            else { return nil }
            return Exercise.Variation(
                initialText: it,
                initialCursorPosition: 0,
                expectedText: et,
                expectedCursorPosition: nil
            )
        }
        // drillCount spans base + variations. The existing engine
        // auto-advances between reps via Exercise.variation(for:).
        let drillCount = 1 + variations.count
        return Exercise(
            id: "generated.\(UUID().uuidString.prefix(8))",
            instruction: instruction,
            initialText: initialText,
            initialCursorPosition: 0,
            expectedText: expectedText,
            expectedCursorPosition: nil,
            hints: hints,
            difficulty: .learn,
            drillCount: drillCount,
            variations: variations,
            optimalKeystrokes: nil,
            futureOptimization: nil
        )
    }

    private static func parseExplanation(_ raw: [[String: Any]]) -> [ContentBlock] {
        raw.compactMap { entry -> ContentBlock? in
            guard let kind = entry["kind"] as? String else { return nil }
            switch kind {
            case "heading":
                guard let t = entry["text"] as? String else { return nil }
                return .heading(t)
            case "text":
                guard let t = entry["text"] as? String else { return nil }
                return .text(t)
            case "tip":
                guard let t = entry["text"] as? String else { return nil }
                return .tip(t)
            case "important":
                guard let t = entry["text"] as? String else { return nil }
                return .important(t)
            case "keyCommand":
                guard let keys = entry["keys"] as? [String],
                      let description = entry["description"] as? String
                else { return nil }
                return .keyCommand(keys: keys, description: description)
            case "spacer":
                return .spacer
            default:
                return nil
            }
        }
    }

    // MARK: - Schema

    private static func makeSchema() -> [String: Any] { [
        "type": "object",
        "additionalProperties": false,
        "required": [
            "visualization", "homeRowKeys",
            "explanation", "exercise",
        ],
        "properties": [
            "visualization": [
                "type": ["string", "null"],
                "enum": [
                    "grammarGrid", "findVsTill", "modesDemo",
                    "modeIndicatorSpotlight", "homeRow",
                    NSNull(),
                ] as [Any],
                "description": "Pick at most one named visualization.",
            ],
            "homeRowKeys": [
                "type": "array",
                "items": ["type": "string"],
                "description": "Only used when visualization == homeRow.",
            ],
            "explanation": [
                "type": "array",
                "description": "2–5 ordered explanation blocks.",
                "items": [
                    "type": "object",
                    "additionalProperties": false,
                    "required": ["kind", "text", "keys", "description"],
                    "properties": [
                        "kind": [
                            "type": "string",
                            "enum": ["heading", "text", "tip", "important",
                                     "keyCommand", "spacer"],
                        ],
                        "text": ["type": ["string", "null"]],
                        "keys": [
                            "type": ["array", "null"],
                            "items": ["type": "string"],
                        ],
                        "description": ["type": ["string", "null"]],
                    ],
                ],
            ],
            "exercise": [
                "type": "object",
                "additionalProperties": false,
                "required": [
                    "instruction", "initialText", "expectedText",
                    "hints", "motionsUsed", "variations",
                ],
                "properties": [
                    "instruction": ["type": "string"],
                    "initialText": ["type": "string"],
                    "expectedText": ["type": "string"],
                    "hints": [
                        "type": "array",
                        "items": ["type": "string"],
                    ],
                    "motionsUsed": [
                        "type": "array",
                        "items": ["type": "string"],
                    ],
                    "variations": [
                        "type": "array",
                        "description": "Exactly 2 additional variations of the same drill.",
                        "items": [
                            "type": "object",
                            "additionalProperties": false,
                            "required": ["initialText", "expectedText"],
                            "properties": [
                                "initialText": ["type": "string"],
                                "expectedText": ["type": "string"],
                            ],
                        ],
                    ],
                ],
            ],
        ],
    ] }
}

import Foundation

/// User-facing choice of which LLM backs tier-3 chat replies
/// (tiers 1 & 2 — canonical Q&A and topic-reference — are model-free
/// regardless). The enum rawValue is what's persisted in
/// `UserDefaults` via `@AppStorage`.
enum AIBackend: String, CaseIterable, Identifiable {
    case apple
    case openAI

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .apple:  "Apple Intelligence (on-device)"
        case .openAI: "OpenAI (cloud)"
        }
    }
}

/// Centralized accessor for the chat-backend preference + API key.
/// Reads UserDefaults for backend selection, Keychain for the key,
/// and falls back to the `OPENAI_API_KEY` environment variable when
/// the stored key is empty — handy during development without
/// pasting the key into the UI every time.
enum AIBackendSettings {
    static let backendKey = "ai.backend"

    static var backend: AIBackend {
        let raw = UserDefaults.standard.string(forKey: backendKey)
            ?? AIBackend.apple.rawValue
        return AIBackend(rawValue: raw) ?? .apple
    }

    /// Key used by the OpenAI backend. Prefers the user-entered value
    /// stored in Keychain; falls back to the process environment when
    /// empty. Returns nil when neither is set — callers should surface
    /// a helpful message in that case.
    static var openAIKey: String? {
        if let stored = KeychainStore.get(.openAIAPIKey),
           !stored.isEmpty {
            return stored
        }
        if let env = ProcessInfo.processInfo.environment["OPENAI_API_KEY"],
           !env.isEmpty {
            return env
        }
        return nil
    }
}

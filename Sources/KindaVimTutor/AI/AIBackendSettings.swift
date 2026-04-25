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

/// User-pickable replacement for any authored `.notes` external
/// drill. The curriculum's drill specs declare `preferredApp:
/// .notes`; when this preference is set to `.bear`, the
/// ExternalTextDrillStepView surface resolver routes those drills
/// to `BearSurface` instead. Lets someone who lives in Bear practice
/// every Notes drill in their actual editor.
enum PreferredNotesApp: String, CaseIterable, Identifiable {
    case notes
    case bear

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .notes: "Apple Notes"
        case .bear:  "Bear"
        }
    }
}

/// Preference accessor for which app any authored `.notes` drill
/// should actually run in. Defaults to Notes. Backed by
/// `UserDefaults` via `@AppStorage` at the settings UI layer.
enum DrillAppPreferences {
    static let preferredNotesKey = "drillApps.preferredNotes"

    static var preferredNotesApp: PreferredNotesApp {
        let raw = UserDefaults.standard.string(forKey: preferredNotesKey)
            ?? PreferredNotesApp.notes.rawValue
        return PreferredNotesApp(rawValue: raw) ?? .notes
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

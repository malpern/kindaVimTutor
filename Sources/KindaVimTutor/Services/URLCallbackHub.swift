import Foundation

/// Routes incoming `kindavim-tutor://` URLs to whatever code was
/// waiting for them. Bear's `x-callback-url/create` uses an
/// `x-success` URL to return the note identifier asynchronously,
/// so the caller (BearSurface) needs a way to register "resolve
/// this continuation when a URL with token T arrives."
///
/// The hub is app-wide (singleton) because URL-open callbacks
/// arrive at `NSApplicationDelegate.application(_:open:)` which has
/// no natural view-context to dispatch from.
@MainActor
final class URLCallbackHub {
    static let shared = URLCallbackHub()
    private init() {}

    /// Map of pending callback tokens → resolvers. A caller
    /// reserves a token, passes it to the external app as part of
    /// an `x-success` URL, and awaits the continuation.
    private var pending: [String: CheckedContinuation<[String: String], Never>] = [:]

    /// Register a new token to await. The returned async value
    /// resolves when `handle(url:)` sees a URL whose first path
    /// component matches.
    func await_(token: String) async -> [String: String] {
        await withCheckedContinuation { continuation in
            pending[token] = continuation
        }
    }

    /// Cancel a pending await — resolve with an empty payload so
    /// the awaiter can move on. Useful when a timeout fires.
    func cancel(token: String) {
        if let c = pending.removeValue(forKey: token) {
            c.resume(returning: [:])
        }
    }

    /// Dispatch an incoming URL. First path component is the token;
    /// query parameters become the payload. Returns true when a
    /// pending awaiter was resumed (the URL was "for us").
    @discardableResult
    func handle(url: URL) -> Bool {
        // URL shape: kindavim-tutor://<token>?k=v&k2=v2
        // `host` is the first component after `://`.
        let token = url.host ?? ""
        guard !token.isEmpty,
              let continuation = pending.removeValue(forKey: token)
        else { return false }
        var fields: [String: String] = [:]
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let items = components.queryItems {
            for item in items {
                fields[item.name] = item.value ?? ""
            }
        }
        continuation.resume(returning: fields)
        return true
    }
}

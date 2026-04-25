import Foundation
import Security

/// Thin wrapper around macOS Keychain for storing the user's OpenAI
/// API key. UserDefaults is fine for preference bits but a raw API
/// key is sensitive — anyone with filesystem access to this user
/// account could read the .plist. Keychain entries are encrypted at
/// rest and gated on login.
enum KeychainStore {
    /// Identifier namespace so multiple tokens can coexist under the
    /// same bundle.
    enum Key: String {
        case openAIAPIKey = "openai-api-key"
        /// Bear's x-callback-url/trash endpoint requires the per-user
        /// API token from Bear → Preferences → Advanced. We need it
        /// to clean up drill notes after a practice session.
        case bearAPIToken = "bear-api-token"
    }

    private static let service = "app.kindavim.tutor"

    /// Store or overwrite. Passing an empty string deletes the entry.
    static func set(_ value: String, for key: Key) {
        if value.isEmpty {
            delete(key)
            return
        }
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]
        let attrs: [String: Any] = [
            kSecValueData as String: data,
        ]
        let updateStatus = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    static func get(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    static func delete(_ key: Key) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

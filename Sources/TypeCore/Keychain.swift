import Foundation
import Security

/// Stores the Anthropic API key in the login keychain.
public enum APIKeyStore {
    private static let service = "Figure Out Your Type"
    private static let account = "Anthropic API Key"

    private static var baseQuery: [CFString: Any] {
        [kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: account]
    }

    /// The saved key, falling back to the ANTHROPIC_API_KEY environment variable.
    public static func load() -> String? {
        var query = baseQuery
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data, let key = String(data: data, encoding: .utf8), !key.isEmpty {
            return key
        }
        let env = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
        return env?.isEmpty == false ? env : nil
    }

    public static var hasSavedKey: Bool {
        var query = baseQuery
        query[kSecMatchLimit] = kSecMatchLimitOne
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    @discardableResult
    public static func save(_ key: String) -> Bool {
        SecItemDelete(baseQuery as CFDictionary)
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        var item = baseQuery
        item[kSecValueData] = Data(trimmed.utf8)
        return SecItemAdd(item as CFDictionary, nil) == errSecSuccess
    }

    public static func delete() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}

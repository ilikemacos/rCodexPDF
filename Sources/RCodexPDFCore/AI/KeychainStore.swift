import Foundation
#if canImport(Security)
import Security
#endif

/// Stores AI provider API keys in the macOS Keychain. Keys are never written to disk in
/// plain text, UserDefaults, or logs — only the Keychain (`kSecClassGenericPassword`) holds them.
public struct KeychainStore: Sendable {
    public enum KeychainError: Error, LocalizedError {
        case unhandled(OSStatus)
        public var errorDescription: String? {
            switch self {
            case .unhandled(let status):
                if let message = SecCopyErrorMessageString(status, nil) as String? {
                    return message
                }
                return "Keychain error \(status)"
            }
        }
    }

    private let service = "com.rcodexpdf.app.apikeys"

    public init() {}

    private func account(for providerID: String) -> String { "provider.\(providerID)" }

    public func setAPIKey(_ key: String, for providerID: String) throws {
        let account = account(for: providerID)
        let data = Data(key.utf8)

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        // Try update first; if no existing item, add one.
        let attributesToUpdate: [String: Any] = [kSecValueData as String: data]
        var status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

        if status == errSecItemNotFound {
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            status = SecItemAdd(query as CFDictionary, nil)
        }

        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status)
        }
    }

    public func getAPIKey(for providerID: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account(for: providerID),
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func hasAPIKey(for providerID: String) -> Bool {
        getAPIKey(for: providerID) != nil
    }

    @discardableResult
    public func deleteAPIKey(for providerID: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account(for: providerID)
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

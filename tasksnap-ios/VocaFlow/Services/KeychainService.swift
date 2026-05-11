import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    private enum Keys {
        static let userId      = "io.vocaflow.app.user_id"
        static let accessToken = "io.vocaflow.app.access_token"
    }

    var userId: String? {
        get { read(key: Keys.userId) }
        set { newValue.map { write(key: Keys.userId, value: $0) } ?? delete(key: Keys.userId) }
    }

    var accessToken: String? {
        get { read(key: Keys.accessToken) }
        set { newValue.map { write(key: Keys.accessToken, value: $0) } ?? delete(key: Keys.accessToken) }
    }

    func clearAll() {
        delete(key: Keys.userId)
        delete(key: Keys.accessToken)
    }

    // MARK: - Private

    private func write(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData:   data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func read(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(key: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

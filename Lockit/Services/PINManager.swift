import Foundation
import Security
import CryptoKit

enum PINError: LocalizedError {
    case keychainWriteFailed(OSStatus)
    case keychainReadFailed
    case noPINStored

    var errorDescription: String? {
        switch self {
        case .keychainWriteFailed(let s): return "Keychain write failed (\(s))."
        case .keychainReadFailed:         return "Keychain read failed."
        case .noPINStored:                return "No PIN is currently stored."
        }
    }
}

final class PINManager {
    static let shared = PINManager()
    private init() {}

    private let hashKey = "lockit.pin.hash"
    private let saltKey = "lockit.pin.salt"

    // MARK: - Generate

    /// Generates a 6-digit PIN, stores its hash+salt in Keychain, returns the plaintext once.
    func generateAndStorePIN() throws -> String {
        let pin = String(format: "%06d", Int.random(in: 0...999_999))
        let salt = UUID().uuidString
        let hash = sha256(salt + pin)

        try storeKeychainString(hash, forKey: hashKey)
        try storeKeychainString(salt, forKey: saltKey)

        return pin
    }

    // MARK: - Verify

    func verifyPIN(_ input: String) -> Bool {
        guard let storedHash = loadKeychainString(forKey: hashKey),
              let salt = loadKeychainString(forKey: saltKey) else {
            return false
        }
        return sha256(salt + input) == storedHash
    }

    // MARK: - Clear

    func clearPIN() {
        deleteKeychainItem(forKey: hashKey)
        deleteKeychainItem(forKey: saltKey)
    }

    var hasPIN: Bool {
        loadKeychainString(forKey: hashKey) != nil
    }

    // MARK: - Hashing

    private func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Keychain helpers

    private func storeKeychainString(_ value: String, forKey key: String) throws {
        let data = Data(value.utf8)
        deleteKeychainItem(forKey: key)

        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData:   data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw PINError.keychainWriteFailed(status)
        }
    }

    private func loadKeychainString(forKey key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteKeychainItem(forKey key: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

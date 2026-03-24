import Foundation
import Security
import LocalAuthentication

/// Service for securely storing and retrieving data from Keychain
final class KeychainService {

    private let serviceName = "com.passkeeper.macos"
    private let primaryPasswordKey = "primaryPasswordHash"
    private let saltKey = "passwordSalt"
    private let dataEncryptionKeyTag = "dataEncryptionKey"
    private let sessionKeyTag = "sessionKey"

    // MARK: - Primary Password

    /// Check if primary password hash is stored
    func hasStoredPasswordHash() -> Bool {
        return getData(forKey: primaryPasswordKey) != nil
    }

    /// Store primary password hash
    func storePrimaryPasswordHash(_ hash: Data, salt: Data) throws {
        try storeData(hash, forKey: primaryPasswordKey)
        try storeData(salt, forKey: saltKey)
    }

    /// Get stored primary password hash
    func getPrimaryPasswordHash() -> Data? {
        return getData(forKey: primaryPasswordKey)
    }

    /// Get stored salt
    func getSalt() -> Data? {
        return getData(forKey: saltKey)
    }

    /// Delete primary password hash and salt
    func deletePrimaryPasswordHash() throws {
        try deleteItem(forKey: primaryPasswordKey)
        try deleteItem(forKey: saltKey)
    }

    // MARK: - Data Encryption Key

    /// Store data encryption key (encrypted by Secure Enclave)
    func storeDataEncryptionKey(_ key: Data) throws {
        try storeData(key, forKey: dataEncryptionKeyTag)
    }

    /// Get data encryption key
    func getDataEncryptionKey() -> Data? {
        return getData(forKey: dataEncryptionKeyTag)
    }

    /// Delete data encryption key
    func deleteDataEncryptionKey() throws {
        try deleteItem(forKey: dataEncryptionKeyTag)
    }

    // MARK: - Session Key

    /// Store session key (without biometric protection for now)
    func storeSessionKey(_ key: Data) throws {
        try storeData(key, forKey: sessionKeyTag)
    }

    /// Retrieve session key
    func getSessionKey() -> Data? {
        return getData(forKey: sessionKeyTag)
    }

    /// Retrieve session key (will trigger biometric if needed) - disabled
    func getSessionKeyWithBiometric() -> Data? {
        let context = LAContext()
        context.localizedReason = "Access session key"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: sessionKeyTag,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: context,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            return nil
        }

        return result as? Data
    }

    /// Delete session key
    func deleteSessionKey() throws {
        try deleteItem(forKey: sessionKeyTag)
    }

    // MARK: - Private Methods

    private func storeData(_ data: Data, forKey key: String) throws {
        // Delete existing item first
        try? deleteItem(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToStore(status: status)
        }
    }

    private func getData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            return nil
        }

        return result as? Data
    }

    private func deleteItem(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete(status: status)
        }
    }
}

/// Keychain errors
enum KeychainError: LocalizedError {
    case unableToStore(status: OSStatus)
    case unableToDelete(status: OSStatus)
    case unableToRetrieve(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .unableToStore(let status):
            return "Unable to store in Keychain: \(status)"
        case .unableToDelete(let status):
            return "Unable to delete from Keychain: \(status)"
        case .unableToRetrieve(let status):
            return "Unable to retrieve from Keychain: \(status)"
        }
    }
}

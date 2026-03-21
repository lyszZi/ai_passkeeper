import Foundation
import Security

/// Service for securely storing and retrieving data from Keychain
final class KeychainService {

    private let serviceName = "com.passkeeper.macos"
    private let masterPasswordKey = "masterPasswordHash"
    private let saltKey = "passwordSalt"
    private let dataEncryptionKeyTag = "dataEncryptionKey"

    // MARK: - Master Password

    /// Check if master password hash is stored
    func hasStoredPasswordHash() -> Bool {
        return getData(forKey: masterPasswordKey) != nil
    }

    /// Store master password hash
    func storeMasterPasswordHash(_ hash: Data, salt: Data) throws {
        try storeData(hash, forKey: masterPasswordKey)
        try storeData(salt, forKey: saltKey)
    }

    /// Get stored master password hash
    func getMasterPasswordHash() -> Data? {
        return getData(forKey: masterPasswordKey)
    }

    /// Get stored salt
    func getSalt() -> Data? {
        return getData(forKey: saltKey)
    }

    /// Delete master password hash and salt
    func deleteMasterPasswordHash() throws {
        try deleteItem(forKey: masterPasswordKey)
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
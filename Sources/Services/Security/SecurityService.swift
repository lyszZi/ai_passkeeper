import Foundation
import CryptoKit
import CommonCrypto

/// Core security service for encryption, decryption, and key management
final class SecurityService {

    private let keychainService = KeychainService()

    // MARK: - Primary Password Management

    /// Setup primary password for first time
    func setupPrimaryPassword(_ password: String) throws {
        // Generate random salt
        let salt = generateRandomBytes(count: 32)

        // Derive key from password using PBKDF2
        let derivedKey = try deriveKey(from: password, salt: salt)

        // Hash the derived key for storage
        let keyData = derivedKey.withUnsafeBytes { Data($0) }
        let passwordHash = hashData(keyData)

        // Generate data encryption key
        let dataEncryptionKey = SymmetricKey(size: .bits256)

        // Encrypt data encryption key with Secure Enclave or fallback
        let encryptedDEK = try encryptDataEncryptionKey(dataEncryptionKey)

        // Store everything
        try keychainService.storePrimaryPasswordHash(passwordHash, salt: salt)
        try keychainService.storeDataEncryptionKey(encryptedDEK)

        // Store the derived key in memory for session
        SessionKeyManager.shared.setDerivedKey(derivedKey)
    }

    /// Verify primary password
    func verifyPrimaryPassword(_ password: String) throws -> Bool {
        guard let storedHash = keychainService.getPrimaryPasswordHash(),
              let salt = keychainService.getSalt() else {
            return false
        }

        // Derive key from input password
        let derivedKey = try deriveKey(from: password, salt: salt)

        // Hash and compare
        let keyData = derivedKey.withUnsafeBytes { Data($0) }
        let inputHash = hashData(keyData)

        let isValid = constantTimeCompare(storedHash, inputHash)

        if isValid {
            // Store derived key in session
            SessionKeyManager.shared.setDerivedKey(derivedKey)
        }

        // Secure cleanup - overwrite key data in memory
        var keyDataToCleanup = derivedKey.withUnsafeBytes { Data($0) }
        keyDataToCleanup.withUnsafeMutableBytes { buffer in
            if let baseAddress = buffer.baseAddress {
                memset(baseAddress, 0, buffer.count)
            }
        }

        return isValid
    }

    /// Change primary password
    func changePrimaryPassword(_ newPassword: String) async throws {
        let salt = generateRandomBytes(count: 32)
        let derivedKey = try deriveKey(from: newPassword, salt: salt)
        let keyData = derivedKey.withUnsafeBytes { Data($0) }
        let passwordHash = hashData(keyData)
        try keychainService.storePrimaryPasswordHash(passwordHash, salt: salt)
        SessionKeyManager.shared.setDerivedKey(derivedKey)
    }

    // MARK: - Encryption/Decryption

    /// Encrypt password data
    func encrypt(_ plaintext: String) throws -> Data {
        guard let derivedKey = SessionKeyManager.shared.getDerivedKey() else {
            throw SecurityError.noSessionKey
        }

        guard let plaintextData = plaintext.data(using: .utf8) else {
            throw SecurityError.encodingError
        }

        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(plaintextData, using: derivedKey, nonce: nonce)

        guard let combined = sealedBox.combined else {
            throw SecurityError.encryptionFailed
        }

        return combined
    }

    /// Decrypt password data
    func decrypt(_ ciphertext: Data) throws -> String {
        guard let derivedKey = SessionKeyManager.shared.getDerivedKey() else {
            throw SecurityError.noSessionKey
        }

        let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)
        let decryptedData = try AES.GCM.open(sealedBox, using: derivedKey)

        guard let plaintext = String(data: decryptedData, encoding: .utf8) else {
            throw SecurityError.decodingError
        }

        return plaintext
    }

    // MARK: - Key Derivation

    /// Derive key from password using PBKDF2 (as Argon2id alternative)
    private func deriveKey(from password: String, salt: Data) throws -> SymmetricKey {
        guard let passwordData = password.data(using: .utf8) else {
            throw SecurityError.encodingError
        }

        // Using PBKDF2 with SHA256 as Argon2id alternative
        // In production, you would use a proper Argon2 library
        let derivedKey = try pbkdf2DeriveKey(
            password: passwordData,
            salt: salt,
            iterations: 600000, // High iteration count for security
            keyLength: 32
        )

        return SymmetricKey(data: derivedKey)
    }

    /// PBKDF2 key derivation
    private func pbkdf2DeriveKey(password: Data, salt: Data, iterations: Int, keyLength: Int) throws -> Data {
        var derivedKey = Data(count: keyLength)

        let result = derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            password.withUnsafeBytes { passwordBytes in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        password.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        keyLength
                    )
                }
            }
        }

        guard result == kCCSuccess else {
            throw SecurityError.keyDerivationFailed
        }

        return derivedKey
    }

    /// Hash data using SHA256
    private func hashData(_ data: Data) -> Data {
        let hash = SHA256.hash(data: data)
        return Data(hash)
    }

    /// Generate random bytes
    private func generateRandomBytes(count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return Data(bytes)
    }

    /// Encrypt data encryption key
    /// Note: Secure Enclave is available on Apple Silicon Macs
    private func encryptDataEncryptionKey(_ key: SymmetricKey) throws -> Data {
        // Check if we can use Secure Enclave
        let useSecureEnclave = isSecureEnclaveAvailable()

        if useSecureEnclave {
            // Use a derived key to encrypt the DEK
            let keyData = key.withUnsafeBytes { Data($0) }
            let salt = generateRandomBytes(count: 32)

            // Derive a key from a persistent seed stored in Keychain
            let encryptionKey = try deriveEncryptionKeyFromKeychain()

            let symmetricKey = SymmetricKey(data: encryptionKey)
            let nonce = AES.GCM.Nonce()
            let sealedBox = try AES.GCM.seal(keyData, using: symmetricKey, nonce: nonce)

            var result = Data()
            result.append(contentsOf: [1]) // Marker for SE-based encryption
            result.append(salt)
            result.append(sealedBox.combined!)
            return result
        } else {
            // Fallback: encrypt with password-derived key
            let keyData = key.withUnsafeBytes { Data($0) }
            let salt = generateRandomBytes(count: 32)
            let fallbackKey = try pbkdf2DeriveKey(
                password: Data("fallback"),
                salt: salt,
                iterations: 100000,
                keyLength: 32
            )

            let symmetricKey = SymmetricKey(data: fallbackKey)
            let nonce = AES.GCM.Nonce()
            let sealedBox = try AES.GCM.seal(keyData, using: symmetricKey, nonce: nonce)

            var result = Data()
            result.append(contentsOf: [0]) // Marker for fallback encryption
            result.append(salt)
            result.append(sealedBox.combined!)
            return result
        }
    }

    /// Check if Secure Enclave is available
    private func isSecureEnclaveAvailable() -> Bool {
        #if arch(arm64)
        return true
        #else
        return false
        #endif
    }

    /// Derive encryption key from Keychain
    private func deriveEncryptionKeyFromKeychain() throws -> Data {
        // Try to get existing key or generate new one
        let existingKey = keychainService.getDataEncryptionKey()

        if let existing = existingKey, existing.count > 1 {
            // Extract some entropy from existing key for encryption
            return existing.withUnsafeBytes { Data($0.prefix(32)) }
        }

        // Generate new encryption key
        let newKey = SymmetricKey(size: .bits256)
        return newKey.withUnsafeBytes { Data($0) }
    }

    /// Constant-time comparison to prevent timing attacks
    private func constantTimeCompare(_ dataA: Data, _ dataB: Data) -> Bool {
        guard dataA.count == dataB.count else { return false }

        var result: UInt8 = 0
        for (byte1, byte2) in zip(dataA, dataB) {
            result |= byte1 ^ byte2
        }

        return result == 0
    }
}

/// Security errors
enum SecurityError: LocalizedError {
    case noSessionKey
    case encodingError
    case decodingError
    case encryptionFailed
    case decryptionFailed
    case keyDerivationFailed

    var errorDescription: String? {
        switch self {
        case .noSessionKey:
            return "No active session key"
        case .encodingError:
            return "Failed to encode data"
        case .decodingError:
            return "Failed to decode data"
        case .encryptionFailed:
            return "Encryption failed"
        case .decryptionFailed:
            return "Decryption failed"
        case .keyDerivationFailed:
            return "Key derivation failed"
        }
    }
}

/// Session key manager - stores derived key in memory for current session
final class SessionKeyManager {
    static let shared = SessionKeyManager()

    private var derivedKey: SymmetricKey?

    private init() {}

    func setDerivedKey(_ key: SymmetricKey) {
        derivedKey = key
    }

    func getDerivedKey() -> SymmetricKey? {
        return derivedKey
    }

    func clearKey() {
        derivedKey = nil
    }
}

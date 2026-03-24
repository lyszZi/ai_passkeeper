import Foundation
import CryptoKit
import CommonCrypto
import XCTest

/// Integration tests for encryption/decryption
/// Tests using CryptoKit directly without app dependencies
final class CryptoKitIntegrationTests: XCTestCase {

    // MARK: - AES-GCM Encryption Tests

    func testAESGCMEncryption() throws {
        let key = SymmetricKey(size: .bits256)
        let plaintext = "MySecretPassword123"

        guard let plaintextData = plaintext.data(using: .utf8) else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode plaintext"])
        }

        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(plaintextData, using: key, nonce: nonce)

        guard let combined = sealedBox.combined else {
            throw NSError(domain: "Test", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to get combined data"])
        }

        // Decrypt
        let decryptedSealedBox = try AES.GCM.SealedBox(combined: combined)
        let decryptedData = try AES.GCM.open(decryptedSealedBox, using: key)

        guard let decryptedText = String(data: decryptedData, encoding: .utf8) else {
            throw NSError(domain: "Test", code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Failed to decode decrypted data"])
        }

        assert(decryptedText == plaintext, "Decrypted text should match plaintext")
    }

    func testDifferentNonceProducesDifferentCiphertext() throws {
        let key = SymmetricKey(size: .bits256)
        let plaintext = "MySecretPassword123"

        guard let plaintextData = plaintext.data(using: .utf8) else {
            throw NSError(domain: "Test", code: 1)
        }

        let nonce1 = AES.GCM.Nonce()
        let sealedBox1 = try AES.GCM.seal(plaintextData, using: key, nonce: nonce1)

        let nonce2 = AES.GCM.Nonce()
        let sealedBox2 = try AES.GCM.seal(plaintextData, using: key, nonce: nonce2)

        assert(sealedBox1.combined != sealedBox2.combined, "Different nonces should produce different ciphertext")
    }

    // MARK: - PBKDF2 Key Derivation Tests

    func testPBKDF2Derivation() throws {
        let password = "TestPassword123"
        let salt = Data(repeating: 0, count: 32)

        guard let passwordData = password.data(using: .utf8) else {
            throw NSError(domain: "Test", code: 1)
        }

        var derivedKey = Data(count: 32)

        let result = derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            passwordData.withUnsafeBytes { passwordBytes in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        passwordData.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(600000),
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        32
                    )
                }
            }
        }

        assert(result == kCCSuccess, "PBKDF2 should succeed")
        assert(derivedKey.count == 32, "Derived key should be 32 bytes")
    }

    func testDifferentSaltsProduceDifferentKeys() throws {
        let password = "TestPassword123"
        let salt1 = Data([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
                         17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32])
        let salt2 = Data([2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
                         18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33])

        let key1 = try deriveKey(password: password, salt: salt1)
        let key2 = try deriveKey(password: password, salt: salt2)

        assert(key1 != key2, "Different salts should produce different keys")
    }

    func testDifferentPasswordsProduceDifferentKeys() throws {
        let salt = Data(repeating: 0, count: 32)

        let key1 = try deriveKey(password: "Password1", salt: salt)
        let key2 = try deriveKey(password: "Password2", salt: salt)

        assert(key1 != key2, "Different passwords should produce different keys")
    }

    private func deriveKey(password: String, salt: Data) throws -> Data {
        guard let passwordData = password.data(using: .utf8) else {
            throw NSError(domain: "Test", code: 1)
        }

        var derivedKey = Data(count: 32)

        let result = derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            passwordData.withUnsafeBytes { passwordBytes in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        passwordData.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(600000),
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        32
                    )
                }
            }
        }

        guard result == kCCSuccess else {
            throw NSError(domain: "Test", code: 2)
        }

        return derivedKey
    }

    // MARK: - SHA256 Hash Tests

    func testSHA256Hash() throws {
        let data = Data("TestString".utf8)
        let hash = SHA256.hash(data: data)

        // Convert digest to array to get count
        let hashArray = Array(hash)
        assert(hashArray.count == 32, "SHA256 hash should be 32 bytes")
    }

    func testSHA256DifferentInputProducesDifferentHash() throws {
        let data1 = Data("String1".utf8)
        let data2 = Data("String2".utf8)

        let hash1 = SHA256.hash(data: data1)
        let hash2 = SHA256.hash(data: data2)

        // Compare hash bytes
        let hash1Bytes = Array(hash1)
        let hash2Bytes = Array(hash2)
        let areDifferent = hash1Bytes != hash2Bytes
        assert(areDifferent, "Different inputs should produce different hashes")
    }

    // MARK: - Random Number Generation Tests

    func testSecureRandomGeneration() throws {
        var bytes1 = [UInt8](repeating: 0, count: 32)
        var bytes2 = [UInt8](repeating: 0, count: 32)

        let result1 = SecRandomCopyBytes(kSecRandomDefault, 32, &bytes1)
        let result2 = SecRandomCopyBytes(kSecRandomDefault, 32, &bytes2)

        assert(result1 == errSecSuccess, "First random generation should succeed")
        assert(result2 == errSecSuccess, "Second random generation should succeed")
        assert(bytes1 != bytes2, "Random bytes should be different")
    }

    // MARK: - Performance Tests

    func testEncryptionPerformance() throws {
        let key = SymmetricKey(size: .bits256)
        let plaintext = String(repeating: "a", count: 100).data(using: .utf8)!

        let start = CFAbsoluteTimeGetCurrent()

        for _ in 0..<100 {
            let nonce = AES.GCM.Nonce()
            _ = try AES.GCM.seal(plaintext, using: key, nonce: nonce)
        }

        let end = CFAbsoluteTimeGetCurrent()
        let avgTime = (end - start) / 100.0

        assert(avgTime < 0.01, "Each encryption should be under 10ms")
    }
}

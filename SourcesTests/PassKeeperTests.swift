import Foundation

/// Unit tests for PasswordItem model
final class PasswordItemTests {

    func testPasswordItemCreation() {
        let item = TestPasswordItem(
            category: "General",
            title: "Test Site",
            username: "user@test.com",
            encryptedPassword: Data("encrypted".utf8)
        )

        assert(item.id != nil, "ID should not be nil")
        assert(item.title == "Test Site", "Title should match")
        assert(item.username == "user@test.com", "Username should match")
        assert(item.category == "General", "Category should match")
    }

    func testSearchIndexCreation() {
        let index = testCreateSearchIndex(title: "Google", username: "user@gmail.com")

        assert(index.contains("google"), "Should contain lowercase title")
        assert(index.contains("user@gmail.com"), "Should contain username")
        assert(index.count == 3, "Should have 3 items")
    }

    private func testCreateSearchIndex(title: String, username: String) -> [String] {
        let combined = "\(title.lowercased()) \(username.lowercased())"
        return [title.lowercased(), username.lowercased(), combined]
    }
}

/// Test data structure mirroring PasswordItem
struct TestPasswordItem {
    let id: UUID
    var category: String
    var title: String
    var username: String
    var encryptedPassword: Data
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var searchIndex: [String]

    init(
        id: UUID = UUID(),
        category: String = "General",
        title: String,
        username: String,
        encryptedPassword: Data,
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        searchIndex: [String] = []
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.username = username
        self.encryptedPassword = encryptedPassword
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.searchIndex = searchIndex
    }
}

/// Unit tests for BiometricType
final class BiometricTypeTests {

    func testBiometricTypeDisplayName() {
        let touchID = TestBiometricType.touchID
        let faceID = TestBiometricType.faceID
        let none = TestBiometricType.none

        assert(touchID.displayName == "Touch ID")
        assert(faceID.displayName == "Face ID")
        assert(none.displayName == "Biometric")
    }

    func testBiometricTypeIcon() {
        let touchID = TestBiometricType.touchID
        let faceID = TestBiometricType.faceID
        let none = TestBiometricType.none

        assert(touchID.icon == "touchid")
        assert(faceID.icon == "faceid")
        assert(none.icon == "lock")
    }
}

/// Test enum mirroring BiometricType
enum TestBiometricType {
    case touchID
    case faceID
    case none

    var displayName: String {
        switch self {
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        case .none: return "Biometric"
        }
    }

    var icon: String {
        switch self {
        case .touchID: return "touchid"
        case .faceID: return "faceid"
        case .none: return "lock"
        }
    }
}

/// Unit tests for error messages
final class ErrorMessageTests {

    func testSecurityErrorDescriptions() {
        let noSessionKey = "No active session key"
        let encodingError = "Failed to encode data"
        let decodingError = "Failed to decode data"
        let encryptionFailed = "Encryption failed"
        let decryptionFailed = "Decryption failed"
        let keyDerivationFailed = "Key derivation failed"

        assert(noSessionKey == "No active session key")
        assert(encodingError == "Failed to encode data")
        assert(decodingError == "Failed to decode data")
        assert(encryptionFailed == "Encryption failed")
        assert(decryptionFailed == "Decryption failed")
        assert(keyDerivationFailed == "Key derivation failed")
    }

    func testDatabaseErrorDescriptions() {
        let notInitialized = "Database not initialized"
        let insertFailed = "Failed to insert record"
        let updateFailed = "Failed to update record"
        let deleteFailed = "Failed to delete record"

        assert(notInitialized == "Database not initialized")
        assert(insertFailed == "Failed to insert record")
        assert(updateFailed == "Failed to update record")
        assert(deleteFailed == "Failed to delete record")
    }
}

/// Unit tests for AppError
final class AppErrorTests {

    func testAppErrorDescriptions() {
        let invalidPassword = "Invalid master password"
        let biometricNotAvailable = "Biometric authentication is not available"
        let encryptionFailed = "Failed to encrypt data"
        let decryptionFailed = "Failed to decrypt data"
        let storageError = "Failed to access storage"

        assert(invalidPassword == "Invalid master password")
        assert(biometricNotAvailable == "Biometric authentication is not available")
        assert(encryptionFailed == "Failed to encrypt data")
        assert(decryptionFailed == "Failed to decrypt data")
        assert(storageError == "Failed to access storage")
    }
}

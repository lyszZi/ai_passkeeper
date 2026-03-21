import Foundation

/// Repository for password operations - coordinates security and storage
final class PasswordRepository {

    private let databaseManager = DatabaseManager.shared
    private let securityService = SecurityService()

    // MARK: - Read Operations

    /// Fetch all passwords (decrypted)
    func fetchAllItems() async throws -> [DecryptedPasswordItem] {
        let encryptedItems = try databaseManager.fetchAllPasswords()
        return try await decryptItems(encryptedItems)
    }

    /// Fetch password by ID (decrypted)
    func fetchItem(id: UUID) async throws -> DecryptedPasswordItem? {
        guard let encryptedItem = try databaseManager.fetchPassword(id: id) else {
            return nil
        }
        return try await decryptSingleItem(encryptedItem)
    }

    /// Search passwords
    func searchItems(query: String) async throws -> [DecryptedPasswordItem] {
        let encryptedItems = try databaseManager.searchPasswords(query: query)
        return try await decryptItems(encryptedItems)
    }

    /// Fetch passwords by category
    func fetchItems(category: String) async throws -> [DecryptedPasswordItem] {
        let encryptedItems = try databaseManager.fetchPasswords(category: category)
        return try await decryptItems(encryptedItems)
    }

    // MARK: - Write Operations

    /// Add new password
    func addItem(
        title: String,
        username: String,
        password: String,
        category: String,
        notes: String
    ) async throws -> DecryptedPasswordItem {
        // Encrypt the password
        let encryptedPassword = try securityService.encrypt(password)

        // Create search index
        let searchIndex = PasswordItem.createSearchIndex(title: title, username: username)

        // Create password item
        let item = PasswordItem(
            category: category,
            title: title,
            username: username,
            encryptedPassword: encryptedPassword,
            notes: notes,
            searchIndex: searchIndex
        )

        // Save to database
        try databaseManager.insertPassword(item)

        // Return decrypted item
        return DecryptedPasswordItem(
            id: item.id,
            category: item.category,
            title: item.title,
            username: item.username,
            password: password,
            notes: item.notes,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt
        )
    }

    /// Update existing password
    func updateItem(
        id: UUID,
        title: String,
        username: String,
        password: String,
        category: String,
        notes: String
    ) async throws {
        // Get existing item
        guard let existingItem = try databaseManager.fetchPassword(id: id) else {
            throw RepositoryError.itemNotFound
        }

        // Encrypt new password
        let encryptedPassword = try securityService.encrypt(password)

        // Update search index
        let searchIndex = PasswordItem.createSearchIndex(title: title, username: username)

        // Create updated item
        let updatedItem = PasswordItem(
            id: existingItem.id,
            category: category,
            title: title,
            username: username,
            encryptedPassword: encryptedPassword,
            notes: notes,
            createdAt: existingItem.createdAt,
            updatedAt: Date(),
            searchIndex: searchIndex
        )

        // Save to database
        try databaseManager.updatePassword(updatedItem)
    }

    /// Delete password
    func deleteItem(id: UUID) throws {
        try databaseManager.deletePassword(id: id)
    }

    // MARK: - Private Helpers

    private func decryptItems(_ items: [PasswordItem]) async throws -> [DecryptedPasswordItem] {
        var decryptedItems: [DecryptedPasswordItem] = []

        for item in items {
            if let decrypted = try? await decryptSingleItem(item) {
                decryptedItems.append(decrypted)
            }
        }

        return decryptedItems
    }

    private func decryptSingleItem(_ item: PasswordItem) async throws -> DecryptedPasswordItem {
        let password = try securityService.decrypt(item.encryptedPassword)
        return DecryptedPasswordItem(from: item, password: password)
    }
}

/// Repository errors
enum RepositoryError: LocalizedError {
    case itemNotFound
    case encryptionFailed
    case decryptionFailed

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Password item not found"
        case .encryptionFailed:
            return "Failed to encrypt password"
        case .decryptionFailed:
            return "Failed to decrypt password"
        }
    }
}
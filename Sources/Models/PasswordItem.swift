import Foundation

/// Represents a password entry in the vault
struct PasswordItem: Identifiable, Codable, Equatable {
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

    /// Creates search index from title and username
    static func createSearchIndex(title: String, username: String) -> [String] {
        let combined = "\(title.lowercased()) \(username.lowercased())"
        return [title.lowercased(), username.lowercased(), combined]
    }
}

/// Decrypted password item for display
struct DecryptedPasswordItem: Identifiable, Equatable {
    let id: UUID
    var category: String
    var title: String
    var username: String
    var password: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(from item: PasswordItem, password: String) {
        self.id = item.id
        self.category = item.category
        self.title = item.title
        self.username = item.username
        self.password = password
        self.notes = item.notes
        self.createdAt = item.createdAt
        self.updatedAt = item.updatedAt
    }

    init(
        id: UUID = UUID(),
        category: String = "General",
        title: String,
        username: String,
        password: String,
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.username = username
        self.password = password
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Password categories
enum PasswordCategory: String, CaseIterable, Codable {
    case general = "General"
    case social = "Social"
    case work = "Work"
    case finance = "Finance"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case other = "Other"

    var icon: String {
        switch self {
        case .general: return "key"
        case .social: return "person.2"
        case .work: return "briefcase"
        case .finance: return "creditcard"
        case .shopping: return "cart"
        case .entertainment: return "tv"
        case .other: return "folder"
        }
    }

    var localizedName: String {
        "category.\(rawValue.lowercased())".localized
    }
}

import Foundation
import SQLite

/// Database manager for SQLite operations using SQLite.swift
final class DatabaseManager {

    static let shared = DatabaseManager()

    private var db: Connection?

    // Table definition
    private let passwords = Table("passwords")
    private let colId = SQLite.Expression<String>("id")
    private let colCategory = SQLite.Expression<String>("category")
    private let colTitle = SQLite.Expression<String>("title")
    private let colUsername = SQLite.Expression<String>("username")
    private let colEncryptedPassword = SQLite.Expression<Data>("encryptedPassword")
    private let colNotes = SQLite.Expression<String>("notes")
    private let colCreatedAt = SQLite.Expression<Double>("createdAt")
    private let colUpdatedAt = SQLite.Expression<Double>("updatedAt")
    private let colSearchIndex = SQLite.Expression<String>("searchIndex")

    private init() {
        do {
            try setupDatabase()
        } catch {
            print("Database setup failed: \(error)")
        }
    }

    // MARK: - Setup

    private func setupDatabase() throws {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("PassKeeper", isDirectory: true)

        // Create directory if needed
        if !fileManager.fileExists(atPath: appFolder.path) {
            try fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)
        }

        let dbPath = appFolder.appendingPathComponent("passwords.sqlite").path

        // Connect to database
        db = try Connection(dbPath)

        // Create tables
        try createTables()
    }

    private func createTables() throws {
        try db?.run(passwords.create(ifNotExists: true) { table in
            table.column(colId, primaryKey: true)
            table.column(colCategory, defaultValue: "General")
            table.column(colTitle)
            table.column(colUsername)
            table.column(colEncryptedPassword)
            table.column(colNotes, defaultValue: "")
            table.column(colCreatedAt)
            table.column(colUpdatedAt)
            table.column(colSearchIndex, defaultValue: "[]")
        })
    }

    // MARK: - CRUD Operations

    /// Fetch all passwords
    func fetchAllPasswords() throws -> [PasswordItem] {
        guard let db = db else {
            throw DatabaseError.notInitialized
        }

        var items: [PasswordItem] = []

        for row in try db.prepare(passwords) {
            if let item = try? mapRowToPasswordItem(row) {
                items.append(item)
            }
        }

        return items
    }

    /// Fetch password by ID
    func fetchPassword(id: UUID) throws -> PasswordItem? {
        guard let db = db else {
            throw DatabaseError.notInitialized
        }

        let query = passwords.filter(colId == id.uuidString)

        guard let row = try db.pluck(query) else {
            return nil
        }

        return try mapRowToPasswordItem(row)
    }

    /// Insert new password
    func insertPassword(_ item: PasswordItem) throws {
        guard let db = db else {
            throw DatabaseError.notInitialized
        }

        let searchIndexJSON = (try? JSONEncoder().encode(item.searchIndex))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        let insert = passwords.insert(
            colId <- item.id.uuidString,
            colCategory <- item.category,
            colTitle <- item.title,
            colUsername <- item.username,
            colEncryptedPassword <- item.encryptedPassword,
            colNotes <- item.notes,
            colCreatedAt <- item.createdAt.timeIntervalSince1970,
            colUpdatedAt <- item.updatedAt.timeIntervalSince1970,
            colSearchIndex <- searchIndexJSON
        )

        try db.run(insert)
    }

    /// Update password
    func updatePassword(_ item: PasswordItem) throws {
        guard let db = db else {
            throw DatabaseError.notInitialized
        }

        let searchIndexJSON = (try? JSONEncoder().encode(item.searchIndex))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        let passwordRow = passwords.filter(colId == item.id.uuidString)

        try db.run(passwordRow.update(
            colCategory <- item.category,
            colTitle <- item.title,
            colUsername <- item.username,
            colEncryptedPassword <- item.encryptedPassword,
            colNotes <- item.notes,
            colUpdatedAt <- item.updatedAt.timeIntervalSince1970,
            colSearchIndex <- searchIndexJSON
        ))
    }

    /// Delete password
    func deletePassword(id: UUID) throws {
        guard let db = db else {
            throw DatabaseError.notInitialized
        }

        let passwordRow = passwords.filter(colId == id.uuidString)
        try db.run(passwordRow.delete())
    }

    /// Search passwords by title or username
    func searchPasswords(query: String) throws -> [PasswordItem] {
        guard let db = db else {
            throw DatabaseError.notInitialized
        }

        let lowercasedQuery = query.lowercased()
        let searchQuery = passwords.filter(
            colTitle.lowercaseString.like("%\(lowercasedQuery)%") ||
            colUsername.lowercaseString.like("%\(lowercasedQuery)%") ||
            colCategory.lowercaseString.like("%\(lowercasedQuery)%")
        )

        var items: [PasswordItem] = []

        for row in try db.prepare(searchQuery) {
            if let item = try? mapRowToPasswordItem(row) {
                items.append(item)
            }
        }

        return items
    }

    /// Fetch passwords by category
    func fetchPasswords(category: String) throws -> [PasswordItem] {
        guard let db = db else {
            throw DatabaseError.notInitialized
        }

        let query = passwords.filter(colCategory == category)

        var items: [PasswordItem] = []

        for row in try db.prepare(query) {
            if let item = try? mapRowToPasswordItem(row) {
                items.append(item)
            }
        }

        return items
    }

    // MARK: - Helper

    private func mapRowToPasswordItem(_ row: Row) throws -> PasswordItem {
        guard let id = UUID(uuidString: row[colId]) else {
            throw DatabaseError.invalidData
        }

        // Parse search index
        let searchIndexJSON: String = row[colSearchIndex]
        var searchIndex: [String] = []
        if let data = searchIndexJSON.data(using: .utf8) {
            searchIndex = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }

        return PasswordItem(
            id: id,
            category: row[colCategory],
            title: row[colTitle],
            username: row[colUsername],
            encryptedPassword: row[colEncryptedPassword],
            notes: row[colNotes],
            createdAt: Date(timeIntervalSince1970: row[colCreatedAt]),
            updatedAt: Date(timeIntervalSince1970: row[colUpdatedAt]),
            searchIndex: searchIndex
        )
    }
}

/// Database errors
enum DatabaseError: LocalizedError {
    case notInitialized
    case insertFailed
    case updateFailed
    case deleteFailed
    case invalidData

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Database not initialized"
        case .insertFailed:
            return "Failed to insert record"
        case .updateFailed:
            return "Failed to update record"
        case .deleteFailed:
            return "Failed to delete record"
        case .invalidData:
            return "Invalid data format"
        }
    }
}

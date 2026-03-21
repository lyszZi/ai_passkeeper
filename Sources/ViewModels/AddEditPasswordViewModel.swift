import Foundation
import Combine

/// ViewModel for adding/editing password
@MainActor
final class AddEditPasswordViewModel: ObservableObject {

    @Published var title: String = ""
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var category: String = "General"
    @Published var notes: String = ""
    @Published var showPassword: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?

    let categories = PasswordCategory.allCases.map { $0.rawValue }

    private let repository = PasswordRepository()
    private var editingItemId: UUID?

    var isEditing: Bool {
        editingItemId != nil
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }

    // MARK: - Load Data

    func loadItem(_ item: DecryptedPasswordItem) {
        editingItemId = item.id
        title = item.title
        username = item.username
        password = item.password
        category = item.category
        notes = item.notes
    }

    func reset() {
        editingItemId = nil
        title = ""
        username = ""
        password = ""
        category = "General"
        notes = ""
        showPassword = false
        errorMessage = nil
    }

    // MARK: - Password Generation

    func generatePassword(
        length: Int = 20,
        includeUppercase: Bool = true,
        includeLowercase: Bool = true,
        includeNumbers: Bool = true,
        includeSymbols: Bool = true
    ) {
        var characters = ""

        if includeUppercase {
            characters += "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        }
        if includeLowercase {
            characters += "abcdefghijklmnopqrstuvwxyz"
        }
        if includeNumbers {
            characters += "0123456789"
        }
        if includeSymbols {
            characters += "!@#$%^&*()_+-=[]{}|;:,.<>?"
        }

        guard !characters.isEmpty else {
            errorMessage = "Please select at least one character type"
            return
        }

        var generatedPassword = ""
        let characterArray = Array(characters)

        for _ in 0..<length {
            var randomByte: UInt8 = 0
            _ = SecRandomCopyBytes(kSecRandomDefault, 1, &randomByte)
            let index = Int(randomByte) % characterArray.count
            generatedPassword.append(characterArray[index])
        }

        password = generatedPassword
        showPassword = true
    }

    // MARK: - Save

    func save() async -> Bool {
        guard isValid else {
            errorMessage = "Please fill in all required fields"
            return false
        }

        isSaving = true
        errorMessage = nil

        do {
            if let itemId = editingItemId {
                // Update existing
                try await repository.updateItem(
                    id: itemId,
                    title: title.trimmingCharacters(in: .whitespaces),
                    username: username.trimmingCharacters(in: .whitespaces),
                    password: password,
                    category: category,
                    notes: notes
                )
            } else {
                // Add new
                _ = try await repository.addItem(
                    title: title.trimmingCharacters(in: .whitespaces),
                    username: username.trimmingCharacters(in: .whitespaces),
                    password: password,
                    category: category,
                    notes: notes
                )
            }

            isSaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
            return false
        }
    }
}
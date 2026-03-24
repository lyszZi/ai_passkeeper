import Foundation
import Combine

/// ViewModel for password list
@MainActor
final class PasswordListViewModel: ObservableObject {

    @Published var passwords: [DecryptedPasswordItem] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: String = "category.all".localized
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let repository = PasswordRepository()
    private var cancellables = Set<AnyCancellable>()

    // 动态计算 categories 以响应语言变化
    var categories: [String] {
        ["category.all".localized] + PasswordCategory.allCases.map { $0.localizedName }
    }

    init() {
        setupSearchObserver()
        setupVaultLockObserver()
    }

    // MARK: - Setup

    private func setupSearchObserver() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                Task {
                    await self?.performSearch(query: query)
                }
            }
            .store(in: &cancellables)
    }

    private func setupVaultLockObserver() {
        NotificationCenter.default.publisher(for: .vaultLocked)
            .sink { [weak self] _ in
                self?.clearSensitiveData()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    func loadPasswords() async {
        isLoading = true
        errorMessage = nil

        do {
            // Compare with English key internally
            if selectedCategory == "category.all".localized || selectedCategory == "All" {
                passwords = try await repository.fetchAllItems()
            } else {
                // Convert localized category back to English for storage
                let matchingCategory = PasswordCategory.allCases.first { $0.localizedName == selectedCategory }
                let categoryKey = matchingCategory?.rawValue ?? selectedCategory
                passwords = try await repository.fetchItems(category: categoryKey)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func filterByCategory(_ category: String) async {
        selectedCategory = category
        await loadPasswords()
    }

    // MARK: - Search

    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            await loadPasswords()
            return
        }

        isLoading = true

        do {
            passwords = try await repository.searchItems(query: query)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Actions

    func deletePassword(_ item: DecryptedPasswordItem) async {
        do {
            try repository.deleteItem(id: item.id)
            passwords.removeAll { $0.id == item.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Security

    private func clearSensitiveData() {
        // Clear passwords from memory
        passwords = []
    }

    func securelyClearAllData() {
        // Overwrite sensitive data in memory
        passwords = []
        searchText = ""
        selectedCategory = "All"
    }
}

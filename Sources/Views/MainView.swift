import SwiftUI

/// Main view with sidebar and content
struct MainView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var listViewModel = PasswordListViewModel()
    @State private var selectedPasswordId: UUID?
    @State private var showingAddSheet = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(viewModel: listViewModel, selectedPasswordId: $selectedPasswordId)
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            if let selectedId = selectedPasswordId,
               let selected = listViewModel.passwords.first(where: { $0.id == selectedId }) {
                PasswordDetailView(item: selected, onDelete: {
                    Task {
                        await listViewModel.deletePassword(selected)
                        selectedPasswordId = nil
                    }
                })
            } else {
                EmptyStateView(onAddNew: { showingAddSheet = true })
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Password", systemImage: "plus")
                }

                Button {
                    appState.lock()
                } label: {
                    Label("Lock", systemImage: "lock")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddEditPasswordView(onSave: {
                Task {
                    await listViewModel.loadPasswords()
                }
            })
        }
        .task {
            await listViewModel.loadPasswords()
        }
        .onReceive(NotificationCenter.default.publisher(for: .addNewPassword)) { _ in
            showingAddSheet = true
        }
    }
}

/// Sidebar with category filter
struct SidebarView: View {
    @ObservedObject var viewModel: PasswordListViewModel
    @Binding var selectedPasswordId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search
            TextField("Search", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            // Password list
            List(viewModel.passwords, id: \.id, selection: $selectedPasswordId) { item in
                PasswordRow(item: item)
                    .tag(item.id)
            }
            .listStyle(.sidebar)

            // Category filter
            Divider()

            List {
                Section("Categories") {
                    ForEach(viewModel.categories, id: \.self) { category in
                        Button {
                            Task {
                                await viewModel.filterByCategory(category)
                            }
                        } label: {
                            HStack {
                                Image(systemName: categoryIcon(for: category))
                                Text(category)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.sidebar)
        }
        .navigationTitle("Passwords")
    }

    private func categoryIcon(for category: String) -> String {
        switch category {
        case "All": return "tray.full"
        case "General": return "key"
        case "Social": return "person.2"
        case "Work": return "briefcase"
        case "Finance": return "creditcard"
        case "Shopping": return "cart"
        case "Entertainment": return "tv"
        default: return "folder"
        }
    }
}

/// Password row in sidebar
struct PasswordRow: View {
    let item: DecryptedPasswordItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.headline)
            Text(item.username)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

/// Empty state when no password selected
struct EmptyStateView: View {
    let onAddNew: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Password Selected")
                .font(.title2)
                .fontWeight(.medium)

            Text("Select a password from the sidebar or create a new one")
                .foregroundStyle(.secondary)

            Button("Add New Password") {
                onAddNew()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
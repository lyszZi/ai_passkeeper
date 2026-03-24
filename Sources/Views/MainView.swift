import SwiftUI

/// Main view with sidebar and content
struct MainView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var i18nService: I18nService
    @StateObject private var listViewModel = PasswordListViewModel()
    @State private var selectedPasswordId: UUID?
    @State private var showingAddSheet = false
    @State private var showingSettings = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                viewModel: listViewModel,
                selectedPasswordId: $selectedPasswordId,
                showingSettings: $showingSettings
            )
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
                    Label("main.addPassword".localized, systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    showingSettings = true
                } label: {
                    Label("settings.title".localized, systemImage: "gearshape")
                }
                .buttonStyle(.bordered)

                Button {
                    appState.lock()
                } label: {
                    Label("main.lock".localized, systemImage: "lock")
                }
                .buttonStyle(.bordered)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
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
    @Binding var showingSettings: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search - 高度增加 1.5 倍
            TextField("main.search".localized, text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)

            // Password list
            List(viewModel.passwords, id: \.id, selection: $selectedPasswordId) { item in
                PasswordRow(item: item)
                    .tag(item.id)
            }
            .listStyle(.sidebar)

            // Category filter
            Divider()

            List {
                Section("main.categories".localized) {
                    ForEach(viewModel.categories, id: \.self) { category in
                        Button {
                            Task {
                                await viewModel.filterByCategory(category)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: categoryIcon(for: category))
                                    .frame(width: 20)
                                Text(category.localized)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .listRowBackground(
                            viewModel.selectedCategory == category ?
                            Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color.clear
                        )
                    }
                }
            }
            .listStyle(.sidebar)

            // Settings button
            Divider()

            Button {
                showingSettings = true
            } label: {
                HStack {
                    Image(systemName: "gearshape")
                    Text("settings.title".localized)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .navigationTitle("main.passwords".localized)
    }

    private func categoryIcon(for category: String) -> String {
        switch category {
        case "category.all".localized: return "tray.full"
        case "category.general".localized: return "key"
        case "category.social".localized: return "person.2"
        case "category.work".localized: return "briefcase"
        case "category.finance".localized: return "creditcard"
        case "category.shopping".localized: return "cart"
        case "category.entertainment".localized: return "tv"
        case "category.other".localized: return "folder"
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

            Text("main.noPasswordSelected".localized)
                .font(.title2)
                .fontWeight(.medium)

            Text("main.noPasswordSelectedDesc".localized)
                .foregroundStyle(.secondary)

            Button("main.addNewPassword".localized) {
                onAddNew()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

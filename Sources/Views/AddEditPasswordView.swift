import SwiftUI

/// View for adding or editing a password entry
struct AddEditPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddEditPasswordViewModel()

    let editingItem: DecryptedPasswordItem?
    let onSave: () -> Void

    init(editingItem: DecryptedPasswordItem? = nil, onSave: @escaping () -> Void) {
        self.editingItem = editingItem
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Text(viewModel.isEditing ? "Edit Password" : "Add Password")
                    .font(.headline)

                Spacer()

                Button("Save") {
                    Task {
                        if await viewModel.save() {
                            onSave()
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.isValid || viewModel.isSaving)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Form
            Form {
                Section {
                    TextField("Title", text: $viewModel.title)
                        .textFieldStyle(.roundedBorder)

                    TextField("Username / Email", text: $viewModel.username)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        if viewModel.showPassword {
                            TextField("Password", text: $viewModel.password)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("Password", text: $viewModel.password)
                                .textFieldStyle(.roundedBorder)
                        }

                        Button {
                            viewModel.showPassword.toggle()
                        } label: {
                            Image(systemName: viewModel.showPassword ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)

                        Menu {
                            Button("Generate Strong Password (20 chars)") {
                                viewModel.generatePassword(length: 20)
                            }
                            Button("Generate 16 chars") {
                                viewModel.generatePassword(length: 16)
                            }
                            Button("Generate 12 chars") {
                                viewModel.generatePassword(length: 12)
                            }
                            Button("Generate 8 chars") {
                                viewModel.generatePassword(length: 8)
                            }
                        } label: {
                            Image(systemName: "wand.and.stars")
                        }
                        .menuStyle(.borderlessButton)
                    }

                    Picker("Category", selection: $viewModel.category) {
                        ForEach(viewModel.categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }

                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 100)
                        .font(.body)
                } header: {
                    Text("Details")
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            .padding()
        }
        .frame(width: 500, height: 450)
        .onAppear {
            if let item = editingItem {
                viewModel.loadItem(item)
            }
        }
    }
}

#Preview("Add") {
    AddEditPasswordView(onSave: { })
}

#Preview("Edit") {
    AddEditPasswordView(
        editingItem: DecryptedPasswordItem(
            title: "Example",
            username: "user@example.com",
            password: "secretpassword"
        ),
        onSave: { }
    )
}
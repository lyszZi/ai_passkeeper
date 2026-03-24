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
                Button("addEdit.cancel".localized) {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Text(viewModel.isEditing ? "main.addPassword".localized : "main.addNewPassword".localized)
                    .font(.headline)

                Spacer()

                Button("addEdit.save".localized) {
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
                    TextField("addEdit.titleField".localized, text: $viewModel.title)
                        .textFieldStyle(.roundedBorder)

                    TextField("addEdit.username".localized, text: $viewModel.username)
                        .textFieldStyle(.roundedBorder)

                    HStack(spacing: 12) {
                        if viewModel.showPassword {
                            TextField("detail.password".localized, text: $viewModel.password)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("detail.password".localized, text: $viewModel.password)
                                .textFieldStyle(.roundedBorder)
                        }

                        // 按钮组
                        HStack(spacing: 4) {
                            Button {
                                viewModel.showPassword.toggle()
                            } label: {
                                Image(systemName: viewModel.showPassword ? "eye.slash" : "eye")
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.borderless)

#if false
                            Menu {
                                Button("addEdit.generateStrong".localized) {
                                    viewModel.generatePassword(length: 20)
                                }
                                Button("addEdit.generate16".localized) {
                                    viewModel.generatePassword(length: 16)
                                }
                                Button("addEdit.generate12".localized) {
                                    viewModel.generatePassword(length: 12)
                                }
                                Button("addEdit.generate8".localized) {
                                    viewModel.generatePassword(length: 8)
                                }
                            } label: {
                                Image(systemName: "wand.and.stars")
                                    .frame(width: 20, height: 20)
                            }
                            .menuStyle(.borderlessButton)
#endif
                        }
                    }

                    Picker("addEdit.category".localized, selection: $viewModel.category) {
                        ForEach(viewModel.categories, id: \.self) { category in
                            Text(category.localized).tag(category)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 100)
                        .font(.body)
                } header: {
                    Text("detail.details".localized)
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

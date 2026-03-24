import SwiftUI
import AppKit

/// Detail view for a password entry
struct PasswordDetailView: View {
    let item: DecryptedPasswordItem
    let onDelete: () -> Void

    @State private var showPassword = false
    @State private var copyFeedback: String?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Image(systemName: "key.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)

                    VStack(alignment: .leading) {
                        Text(item.title)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(item.category)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                Divider()

                // Username
                DetailRow(label: "detail.username".localized, value: item.username) {
                    copyToClipboard(item.username)
                }

                // Password
                VStack(alignment: .leading, spacing: 8) {
                    Text("detail.password".localized)
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    HStack {
                        if showPassword {
                            Text(item.password)
                                .font(.system(.body, design: .monospaced))
                        } else {
                            Text(String(repeating: "•", count: min(item.password.count, 20)))
                                .font(.system(.body, design: .monospaced))
                        }

                        Spacer()

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)

                        Button {
                            copyToClipboard(item.password)
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)

                    if let feedback = copyFeedback {
                        Text(feedback)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    Text("detail.copySuccess".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Notes
                if !item.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("detail.notes".localized)
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text(item.notes)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)
                    }
                }

                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    Text("detail.details".localized)
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text("detail.created".localized)
                            .foregroundStyle(.secondary)
                        Text(item.createdAt, style: .date)
                    }
                    .font(.caption)

                    HStack {
                        Text("detail.lastModified".localized)
                            .foregroundStyle(.secondary)
                        Text(item.updatedAt, style: .date)
                    }
                    .font(.caption)
                }

                Spacer()

                // Delete button
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("detail.deletePassword".localized, systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("detail.deletePassword".localized + "?", isPresented: $showingDeleteConfirmation) {
            Button("detail.cancel".localized, role: .cancel) { }
            Button("detail.delete".localized, role: .destructive) {
                onDelete()
            }
        } message: {
            Text("detail.deleteConfirm".localized + " \"\(item.title)\"? " + "detail.deleteWarning".localized)
        }
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        // Set feedback
        copyFeedback = "detail.copied".localized

        // Schedule clipboard clearing after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if NSPasteboard.general.string(forType: .string) == text {
                NSPasteboard.general.clearContents()
            }
            withAnimation {
                copyFeedback = nil
            }
        }
    }
}

/// Detail row with copy button
struct DetailRow: View {
    let label: String
    let value: String
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack {
                Text(value)
                    .textSelection(.enabled)

                Spacer()

                Button {
                    onCopy()
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

#Preview {
    PasswordDetailView(
        item: DecryptedPasswordItem(
            title: "Example",
            username: "user@example.com",
            password: "secretpassword123",
            notes: "This is a test note"
        ),
        onDelete: { }
    )
}

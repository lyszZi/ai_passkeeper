import SwiftUI

/// Settings view with language selection and password reset
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var i18nService: I18nService
    @State private var showingResetSheet = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Text("settings.title".localized)
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            Form {
                Section {
                    Picker("settings.language".localized, selection: $viewModel.selectedLanguage) {
                        ForEach(I18nService.Language.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .onChange(of: viewModel.selectedLanguage) { newValue in
                        viewModel.updateLanguage(newValue)
                    }

                    Picker("settings.appearance".localized, selection: $viewModel.selectedAppearance) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .onChange(of: viewModel.selectedAppearance) { newValue in
                        viewModel.updateAppearance(newValue)
                    }
                } header: {
                    Text("settings.general".localized)
                }

                Section {
                    Button("settings.resetPassword".localized) {
                        showingResetSheet = true
                    }
                } header: {
                    Text("settings.security".localized)
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 400, minHeight: 300)
        .sheet(isPresented: $showingResetSheet) {
            PasswordResetView(viewModel: viewModel)
        }
    }
}

/// Password reset view
struct PasswordResetView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("settings.resetPassword".localized)
                .font(.headline)

            SecureField("settings.currentPassword".localized, text: $currentPassword)
                .textFieldStyle(.roundedBorder)

            SecureField("settings.newPassword".localized, text: $newPassword)
                .textFieldStyle(.roundedBorder)

            SecureField("settings.confirmPassword".localized, text: $confirmPassword)
                .textFieldStyle(.roundedBorder)

            if showError {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            HStack {
                Button("detail.cancel".localized) {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("settings.reset".localized) {
                    Task {
                        await resetPassword()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
        }
        .padding(30)
        .frame(width: 350)
        .onChange(of: viewModel.passwordResetSuccess) { success in
            if success {
                dismiss()
            }
        }
        .onChange(of: viewModel.passwordResetError) { error in
            if let error = error {
                showError = true
                errorMessage = error
            }
        }
    }

    private var isValid: Bool {
        currentPassword.count >= 6 &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword
    }

    private func resetPassword() async {
        showError = false

        if newPassword.count < 6 {
            errorMessage = "settings.passwordMinLength".localized
            showError = true
            return
        }

        if newPassword != confirmPassword {
            errorMessage = "settings.passwordMismatch".localized
            showError = true
            return
        }

        let success = await viewModel.resetPassword(
            currentPassword: currentPassword,
            newPassword: newPassword
        )

        if !success {
            showError = true
            errorMessage = viewModel.passwordResetError ?? "settings.resetFailed".localized
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(I18nService.shared)
}

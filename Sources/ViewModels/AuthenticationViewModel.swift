import Foundation

/// ViewModel for authentication (unlock/setup screens)
@MainActor
final class AuthenticationViewModel: ObservableObject {

    @Published var primaryPassword: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showPassword: Bool = false

    private let appState = AppState.shared
    private let securityService = SecurityService()

    var isFirstLaunch: Bool {
        appState.isFirstLaunch
    }

    var biometricType: BiometricType {
        appState.biometricType
    }

    var isBiometricAvailable: Bool {
        biometricType != .none
    }

    // MARK: - Setup Primary Password

    func setupPrimaryPassword() async -> Bool {
        guard !primaryPassword.isEmpty else {
            errorMessage = "Please enter a primary password"
            return false
        }

        guard primaryPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            return false
        }

        guard primaryPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            try await appState.setupPrimaryPassword(primaryPassword)
            clearSensitiveData()
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Unlock with Password

    func unlockWithPassword() async -> Bool {
        guard !primaryPassword.isEmpty else {
            errorMessage = "Please enter your primary password"
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let isValid = try await appState.verifyPrimaryPassword(primaryPassword)
            if isValid {
                clearSensitiveData()
            } else {
                errorMessage = "Invalid primary password"
            }
            isLoading = false
            return isValid
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Unlock with Biometric

    func unlockWithBiometric() async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let success = try await appState.unlockWithBiometric()
            isLoading = false
            return success
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Security

    private func clearSensitiveData() {
        // Overwrite password in memory
        primaryPassword = ""
        confirmPassword = ""
    }

    func reset() {
        primaryPassword = ""
        confirmPassword = ""
        errorMessage = nil
        showPassword = false
    }
}

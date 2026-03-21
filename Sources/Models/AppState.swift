import Foundation
import SwiftUI

/// Application state manager
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isLocked: Bool = true
    @Published var isFirstLaunch: Bool = true
    @Published var isSetupComplete: Bool = false
    @Published var biometricType: BiometricType = .none

    private let keychainService = KeychainService()
    private let securityService = SecurityService()

    private init() {
        checkFirstLaunch()
        checkBiometricAvailability()
    }

    private func checkFirstLaunch() {
        let hasPassword = keychainService.hasStoredPasswordHash()
        isFirstLaunch = !hasPassword
        isSetupComplete = hasPassword
    }

    private func checkBiometricAvailability() {
        biometricType = LocalAuthService.shared.biometricType
    }

    // MARK: - Authentication

    /// Setup master password for first time
    func setupMasterPassword(_ password: String) async throws {
        try securityService.setupMasterPassword(password)
        await MainActor.run {
            self.isFirstLaunch = false
            self.isSetupComplete = true
            self.isLocked = false
        }
    }

    /// Verify master password
    func verifyMasterPassword(_ password: String) async throws -> Bool {
        let isValid = try securityService.verifyMasterPassword(password)
        if isValid {
            await MainActor.run {
                self.isLocked = false
            }
        }
        return isValid
    }

    /// Unlock with biometric
    func unlockWithBiometric() async throws -> Bool {
        let isAuthenticated = try await LocalAuthService.shared.authenticate(reason: "Unlock PassKeeper")
        if isAuthenticated {
            await MainActor.run {
                self.isLocked = false
            }
        }
        return isAuthenticated
    }

    /// Lock the vault
    func lock() {
        isLocked = true
        secureCleanup()
    }

    /// Secure cleanup of sensitive data
    func secureCleanup() {
        // Post notification to clear all sensitive data in ViewModels
        NotificationCenter.default.post(name: .vaultLocked, object: nil)
    }

    /// Change master password
    func changeMasterPassword(currentPassword: String, newPassword: String) async throws {
        let isValid = try securityService.verifyMasterPassword(currentPassword)
        guard isValid else {
            throw AppError.invalidPassword
        }
        try await securityService.changeMasterPassword(newPassword)
    }
}

/// Supported biometric types
enum BiometricType {
    case touchID
    case faceID
    case none

    var displayName: String {
        switch self {
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        case .none: return "Biometric"
        }
    }

    var icon: String {
        switch self {
        case .touchID: return "touchid"
        case .faceID: return "faceid"
        case .none: return "lock"
        }
    }
}

/// Application errors
enum AppError: LocalizedError {
    case invalidPassword
    case biometricNotAvailable
    case encryptionFailed
    case decryptionFailed
    case storageError
    case keychainError(String)
    case setupIncomplete

    var errorDescription: String? {
        switch self {
        case .invalidPassword:
            return "Invalid master password"
        case .biometricNotAvailable:
            return "Biometric authentication is not available"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .storageError:
            return "Failed to access storage"
        case .keychainError(let message):
            return "Keychain error: \(message)"
        case .setupIncomplete:
            return "Application setup is incomplete"
        }
    }
}

extension Notification.Name {
    static let vaultLocked = Notification.Name("vaultLocked")
}
import Foundation
import LocalAuthentication

/// Service for biometric authentication (Touch ID / Face ID)
final class LocalAuthService {

    static let shared = LocalAuthService()

    private let context = LAContext()

    private init() {}

    // MARK: - Biometric Type

    /// Get the type of biometric available on device
    var biometricType: BiometricType {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .faceID // Treat Optic ID similar to Face ID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    /// Check if biometric authentication is available
    var isBiometricAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    // MARK: - Authentication

    /// Authenticate user with biometrics
    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Master Password"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AppError.biometricNotAvailable
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch {
            throw AppError.biometricNotAvailable
        }
    }

    /// Authenticate user with biometrics or device passcode as fallback
    func authenticateWithFallback(reason: String) async throws -> Bool {
        let context = LAContext()

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return success
        } catch {
            throw AppError.biometricNotAvailable
        }
    }
}
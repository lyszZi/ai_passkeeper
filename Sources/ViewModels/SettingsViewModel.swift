import Foundation
import SwiftUI
import AppKit

/// ViewModel for Settings screen
@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var selectedLanguage: I18nService.Language
    @Published var selectedAppearance: AppearanceMode
    @Published var showingPasswordReset = false
    @Published var passwordResetError: String?
    @Published var passwordResetSuccess = false

    private let i18nService = I18nService.shared
    private let appearanceKey = "app_appearance_mode"

    init() {
        self.selectedLanguage = i18nService.currentLanguage
        let storedValue = UserDefaults.standard.integer(forKey: appearanceKey)
        self.selectedAppearance = AppearanceMode(rawValue: storedValue) ?? .system
    }

    func updateLanguage(_ language: I18nService.Language) {
        i18nService.setLanguage(language)
        selectedLanguage = language
    }

    func updateAppearance(_ mode: AppearanceMode) {
        selectedAppearance = mode
        UserDefaults.standard.set(mode.rawValue, forKey: appearanceKey)
        applyAppearance(mode)
    }

    private func applyAppearance(_ mode: AppearanceMode) {
        switch mode {
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .system:
            NSApp.appearance = nil
        }
    }

    func resetPassword(currentPassword: String, newPassword: String) async -> Bool {
        do {
            try await AppState.shared.changePrimaryPassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            passwordResetSuccess = true
            return true
        } catch {
            passwordResetError = error.localizedDescription
            return false
        }
    }
}

/// Appearance mode enum
enum AppearanceMode: Int, CaseIterable, Identifiable {
    case system = 0
    case light = 1
    case dark = 2

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .system: return "settings.appearance.system".localized
        case .light: return "settings.appearance.light".localized
        case .dark: return "settings.appearance.dark".localized
        }
    }
}

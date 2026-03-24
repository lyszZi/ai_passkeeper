import Foundation
import SwiftUI

/// Service for managing internationalization (i18n)
final class I18nService: ObservableObject {
    static let shared = I18nService()

    /// Supported languages
    enum Language: String, CaseIterable, Identifiable {
        case english = "en"
        case chinese = "zh-Hans"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .english: return "English"
            case .chinese: return "简体中文"
            }
        }

        var locale: Locale {
            Locale(identifier: rawValue)
        }
    }

    /// Current selected language
    @Published var currentLanguage: Language {
        didSet {
            saveLanguagePreference()
            objectWillChange.send()
        }
    }

    private let languageKey = "app_language_preference"

    private init() {
        // Load saved preference or detect system language
        currentLanguage = I18nService.loadSavedLanguage() ?? I18nService.detectSystemLanguage()
    }

    /// Load language preference from UserDefaults
    private static func loadSavedLanguage() -> Language? {
        guard let savedCode = UserDefaults.standard.string(forKey: "app_language_preference"),
              let language = Language(rawValue: savedCode) else {
            return nil
        }
        return language
    }

    /// Detect system language
    private static func detectSystemLanguage() -> Language {
        let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        if systemLanguage.hasPrefix("zh") {
            return .chinese
        }
        return .english
    }

    /// Save language preference to UserDefaults
    private func saveLanguagePreference() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
    }

    /// Switch to a specific language
    func setLanguage(_ language: Language) {
        currentLanguage = language
    }

    /// Get localized string for a key
    func localizedString(forKey key: String) -> String {
        let bundlePath = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj")
        let bundle = bundlePath.flatMap { Bundle(path: $0) } ?? .main
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }
}

/// View modifier to apply localization
struct LocalizedText: View {
    let key: String

    var body: some View {
        Text(I18nService.shared.localizedString(forKey: key))
    }
}

/// Custom String extension for localization
extension String {
    var localized: String {
        I18nService.shared.localizedString(forKey: self)
    }
}

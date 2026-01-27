import Foundation

// MARK: - App Language Enum

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case zhHant
    case zhHans
    case en
    case ja
    case ko
    case es
    case fr
    case de
    case pt

    var id: String { rawValue }

    /// Display name in the language's native form
    var displayName: String {
        switch self {
        case .system:
            return String(localized: "settings.followSystem")
        case .zhHant:
            return "繁體中文"
        case .zhHans:
            return "简体中文"
        case .en:
            return "English"
        case .ja:
            return "日本語"
        case .ko:
            return "한국어"
        case .es:
            return "Español"
        case .fr:
            return "Français"
        case .de:
            return "Deutsch"
        case .pt:
            return "Português"
        }
    }

    /// Locale identifier for the language
    var localeIdentifier: String {
        switch self {
        case .system:
            return Locale.current.identifier
        case .zhHant:
            return "zh-Hant"
        case .zhHans:
            return "zh-Hans"
        case .en:
            return "en"
        case .ja:
            return "ja"
        case .ko:
            return "ko"
        case .es:
            return "es"
        case .fr:
            return "fr"
        case .de:
            return "de"
        case .pt:
            return "pt"
        }
    }
}

// MARK: - Language Manager

@Observable
final class LanguageManager {
    // MARK: - Singleton

    static let shared = LanguageManager()

    // MARK: - Constants

    private enum Keys {
        static let appLanguage = "appLanguage"
    }

    // MARK: - Properties

    var selectedLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: Keys.appLanguage)
        }
    }

    /// Current locale based on selected language
    var currentLocale: Locale {
        if selectedLanguage == .system {
            return Locale.current
        }
        return Locale(identifier: selectedLanguage.localeIdentifier)
    }

    /// Display name of the current language
    var currentLanguageDisplayName: String {
        if selectedLanguage == .system {
            // Get the system language's display name
            let systemLocale = Locale.current
            return systemLocale.localizedString(forIdentifier: systemLocale.identifier) ?? "Unknown"
        }
        return selectedLanguage.displayName
    }

    // MARK: - Initialization

    private init() {
        if let savedValue = UserDefaults.standard.string(forKey: Keys.appLanguage),
           let language = AppLanguage(rawValue: savedValue)
        {
            selectedLanguage = language
        } else {
            selectedLanguage = .system
        }
    }
}

import Foundation

final class LocalizationManager {
    
    static let shared = LocalizationManager()
    
    private let userDefaultsKey = "appUILanguage"
    
    // Поддерживаемые языки UI: английский и русский
    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: userDefaultsKey)
        }
    }
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey),
           let lang = AppLanguage(rawValue: saved) {
            currentLanguage = lang
        } else {
            // По умолчанию используем язык системы, но только en / ru
            let system = AppLanguage.fromCurrentLocale()
            switch system {
            case .russian:
                currentLanguage = .russian
            default:
                currentLanguage = .english
            }
        }
    }
    
    private var bundle: Bundle {
        let languageCode: String
        switch currentLanguage {
        case .russian:
            languageCode = "ru"
        default:
            languageCode = "en"
        }
        
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        
        return .main
    }
    
    func localizedString(_ key: String, comment: String = "") -> String {
        return NSLocalizedString(key, bundle: bundle, comment: comment)
    }
}

// Глобальная функция для локализации
func tr(_ key: String) -> String {
    return LocalizationManager.shared.localizedString(key)
}


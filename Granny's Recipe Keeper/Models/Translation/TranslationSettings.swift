//
//  TranslationSettings.swift
//  Granny's
//
//  Created by AI on 18.02.2026.
//

import Foundation

/// Настройки перевода на уровне приложения
final class TranslationSettings {
    
    static let shared = TranslationSettings()
    
    private let userDefaults = UserDefaults.standard
    private let languageKey = "PreferredRecipeLanguage"
    
    private init() {}
    
    var preferredLanguage: AppLanguage {
        get {
            if let stored = userDefaults.string(forKey: languageKey),
               let lang = AppLanguage(rawValue: stored) {
                return lang
            }
            return AppLanguage.fromCurrentLocale()
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: languageKey)
        }
    }
}


//
//  RecipeTranslationModels.swift
//  Granny's
//
//  Created by AI on 18.02.2026.
//

import Foundation

/// Поддерживаемые языки перевода рецептов
enum AppLanguage: String, CaseIterable {
    case english = "en"
    case russian = "ru"
    case french = "fr"
    case german = "de"
    case spanish = "es"
    case portuguese = "pt"
    case chineseSimplified = "zh-Hans"
    case japanese = "ja"
    case arabic = "ar"
    case hindi = "hi"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .russian: return "Русский"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .spanish: return "Español"
        case .portuguese: return "Português"
        case .chineseSimplified: return "简体中文"
        case .japanese: return "日本語"
        case .arabic: return "العربية"
        case .hindi: return "हिन्दी"
        }
    }
    
    /// Короткий код языка для UI (EN, RU, FR, DE, ...)
    var shortCode: String {
        return String(rawValue.prefix(2)).uppercased()
    }
    
    /// Идентификатор для Translation API
    var localeIdentifier: String {
        switch self {
        case .english: return "en-US"
        case .russian: return "ru-RU"
        case .french: return "fr-FR"
        case .german: return "de-DE"
        case .spanish: return "es-ES"
        case .portuguese: return "pt-PT"
        case .chineseSimplified: return "zh-Hans-CN"
        case .japanese: return "ja-JP"
        case .arabic: return "ar-SA"
        case .hindi: return "hi-IN"
        }
    }
    
    static func fromCurrentLocale() -> AppLanguage {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        
        if code.starts(with: "ru") { return .russian }
        if code.starts(with: "fr") { return .french }
        if code.starts(with: "de") { return .german }
        if code.starts(with: "es") { return .spanish }
        if code.starts(with: "pt") { return .portuguese }
        if code.starts(with: "zh") { return .chineseSimplified }
        if code.starts(with: "ja") { return .japanese }
        if code.starts(with: "ar") { return .arabic }
        if code.starts(with: "hi") { return .hindi }
        
        return .english
    }
}

/// Переведённый текст рецепта для одного языка
struct RecipeTranslationPayload: Codable {
    let languageCode: String
    let name: String
    let instructions: String?
    let ingredientsText: String?
    let tags: String?
}


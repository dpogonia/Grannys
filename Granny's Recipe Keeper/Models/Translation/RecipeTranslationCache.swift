//
//  RecipeTranslationCache.swift
//  Granny's
//
//  Created by AI on 18.02.2026.
//

import Foundation

/// Кэш переведённых текстов рецептов (работает оффлайн, хранится в UserDefaults)
final class RecipeTranslationCache {
    
    static let shared = RecipeTranslationCache()
    
    private let userDefaults = UserDefaults.standard
    private let baseKey = "RecipeTranslationCache"
    
    private init() {}
    
    private func key(for recipeId: UUID, languageCode: String) -> String {
        return "\(baseKey)_\(recipeId.uuidString)_\(languageCode)"
    }
    
    func loadTranslation(recipeId: UUID, language: AppLanguage) -> RecipeTranslationPayload? {
        let key = self.key(for: recipeId, languageCode: language.rawValue)
        guard let data = userDefaults.data(forKey: key) else { return nil }
        
        return try? JSONDecoder().decode(RecipeTranslationPayload.self, from: data)
    }
    
    func saveTranslation(_ translation: RecipeTranslationPayload, for recipeId: UUID) {
        let key = self.key(for: recipeId, languageCode: translation.languageCode)
        if let data = try? JSONEncoder().encode(translation) {
            userDefaults.set(data, forKey: key)
        }
    }
}


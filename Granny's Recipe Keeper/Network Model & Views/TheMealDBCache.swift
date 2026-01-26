//
//  TheMealDBCache.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import Foundation

// MARK: - TheMealDBCache
// TheMealDBCache - это кэш для сохранения рецептов из TheMealDB API
// Использует UserDefaults для хранения данных на устройстве
// Это позволяет показывать рецепты даже без интернета (последние загруженные)
// UserDefaults - это простое хранилище ключ-значение, как словарь, который сохраняется между запусками приложения
class TheMealDBCache {
    // Singleton паттерн - один экземпляр на всё приложение
    static let shared = TheMealDBCache()
    
    // UserDefaults - это хранилище настроек и простых данных приложения
    // Сохраняет данные на диск, чтобы они остались после перезапуска приложения
    private let userDefaults = UserDefaults.standard
    
    // Ключ для сохранения кэшированных рецептов в UserDefaults
    private let cacheKey = "TheMealDB_CachedRecipes"
    
    // Приватный инициализатор (часть паттерна Singleton)
    private init() {}
    
    func cacheRecipes(_ recipes: [TheMealDBRecipe]) {
        if let encoded = try? JSONEncoder().encode(recipes) {
            userDefaults.set(encoded, forKey: cacheKey)
        }
    }
    
    func getCachedRecipes() -> [TheMealDBRecipe]? {
        guard let data = userDefaults.data(forKey: cacheKey),
              let recipes = try? JSONDecoder().decode([TheMealDBRecipe].self, from: data) else {
            return nil
        }
        return recipes
    }
    
    func clearCache() {
        userDefaults.removeObject(forKey: cacheKey)
    }
}

//
//  TheMealDBCache.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import Foundation

class TheMealDBCache {
    static let shared = TheMealDBCache()
    
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "TheMealDB_CachedRecipes"
    
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

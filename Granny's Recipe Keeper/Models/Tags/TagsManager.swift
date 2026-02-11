//
//  TagsManager.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import Foundation

class TagsManager {
    static let shared = TagsManager()
    
    private let customTagsKey = "CustomTags"
    private let deletedTagsKey = "DeletedTags"
    
    let defaultTags = [
        "Vegetarian",
        "Vegan",
        "Gluten-Free",
        "Lactose-Free",
        "Low-Calorie",
        "Quick",
        "Kid-Friendly",
        "Spicy",
        "Sweet",
        "Healthy",
        "Sugar-Free",
        "Nut-Free"
    ]
    
    private init() {}
    
    func getCustomTags() -> [String] {
        return UserDefaults.standard.array(forKey: customTagsKey) as? [String] ?? []
    }
    
    func addCustomTag(_ tag: String) {
        let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty else { return }
        
        var customTags = getCustomTags()
        
        if !customTags.contains(trimmedTag) {
            customTags.append(trimmedTag)
            customTags.sort()
            UserDefaults.standard.set(customTags, forKey: customTagsKey)
        }
    }
    
    func deleteCustomTag(_ tag: String) {
        var customTags = getCustomTags()
        customTags.removeAll { $0 == tag }
        UserDefaults.standard.set(customTags, forKey: customTagsKey)
        
        var deletedTags = getDeletedTags()
        deletedTags.insert(tag)
        UserDefaults.standard.set(Array(deletedTags), forKey: deletedTagsKey)
    }
    
    func renameTag(oldName: String, newName: String) {
        let trimmedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNewName.isEmpty else { return }
        
        var customTags = getCustomTags()
        if let index = customTags.firstIndex(of: oldName) {
            customTags[index] = trimmedNewName
            customTags.sort()
            UserDefaults.standard.set(customTags, forKey: customTagsKey)
        }
        
        let allRecipes = RecipesRepository.shared.getAllRecipes(archived: false)
        for recipe in allRecipes {
            if recipe.tags.contains(oldName) {
                var updatedTags = recipe.tags
                if let tagIndex = updatedTags.firstIndex(of: oldName) {
                    updatedTags[tagIndex] = trimmedNewName
                    var updatedRecipe = recipe
                    updatedRecipe.tags = updatedTags
                    RecipesRepository.shared.saveRecipe(updatedRecipe)
                }
            }
        }
    }
    
    func getDeletedTags() -> Set<String> {
        let array = UserDefaults.standard.array(forKey: deletedTagsKey) as? [String] ?? []
        return Set(array)
    }
    
    func getAllAvailableTags() -> [String] {
        let customTags = getCustomTags()
        let deletedTags = getDeletedTags()
        
        let allTags = defaultTags + customTags
        
        return allTags.filter { !deletedTags.contains($0) }
    }
    
    func getAllTagsFromRecipes() -> [String] {
        let allRecipes = RecipesRepository.shared.getAllRecipes(archived: false)
        var tagsSet: Set<String> = []
        
        for recipe in allRecipes {
            for tag in recipe.tags {
                tagsSet.insert(tag)
            }
        }
        
        let availableTags = getAllAvailableTags()
        for tag in availableTags {
            tagsSet.insert(tag)
        }
        
        return Array(tagsSet).sorted()
    }
}

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
        var deletedTags = getDeletedTags()
        
        if let index = customTags.firstIndex(of: oldName) {
            customTags[index] = trimmedNewName
        } else if defaultTags.contains(oldName) {
            deletedTags.insert(oldName)
            if !customTags.contains(trimmedNewName) {
                customTags.append(trimmedNewName)
            }
        } else if !customTags.contains(trimmedNewName) {
            customTags.append(trimmedNewName)
        }
        
        customTags.sort()
        UserDefaults.standard.set(customTags, forKey: customTagsKey)
        UserDefaults.standard.set(Array(deletedTags), forKey: deletedTagsKey)
        
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
    
    func setCustomTags(_ tags: [String]) {
        let sorted = tags.sorted()
        UserDefaults.standard.set(sorted, forKey: customTagsKey)
    }
    
    func setDeletedTags(_ tags: Set<String>) {
        UserDefaults.standard.set(Array(tags), forKey: deletedTagsKey)
    }
    
    func restoreState(customTags: [String], deletedTags: Set<String>) {
        setCustomTags(customTags)
        setDeletedTags(deletedTags)
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
        let deletedTags = getDeletedTags()
        
        for recipe in allRecipes {
            for tag in recipe.tags {
                guard !deletedTags.contains(tag) else { continue }
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

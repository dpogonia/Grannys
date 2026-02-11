//
//  RecipesRepository.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import Foundation
import CoreData
import UIKit

class RecipesRepository {
    static let shared = RecipesRepository()
    
    private let context: NSManagedObjectContext
    
    private init() {
        self.context = CoreDataManager.shared.viewContext
        initializeDefaultCategoriesIfNeeded()
    }
    
    // MARK: - Categories
    func getAllCategories() -> [Category] {
        let fetchRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        
        do {
            let entities = try context.fetch(fetchRequest)
            let categories = entities.compactMap { Category(from: $0) }
            
            let sortedCategories = categories.sorted { category1, category2 in
                if category1.order != category2.order {
                    return category1.order < category2.order
                }
                return category1.name < category2.name
            }
            
            return sortedCategories
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }
    
    func getCategory(by id: UUID) -> Category? {
        let fetchRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let entity = try context.fetch(fetchRequest).first {
                return Category(from: entity)
            }
        } catch {
            print("Error fetching category: \(error)")
        }
        return nil
    }
    
    func saveCategory(_ category: Category) {
        let fetchRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", category.id as CVarArg)
        
        do {
            if let existing = try context.fetch(fetchRequest).first {
                existing.name = category.name
                existing.isDefault = category.isDefault
                existing.order = category.order
            } else {
                _ = category.toEntity(in: context)
            }
            CoreDataManager.shared.saveContext()
        } catch {
            print("Error saving category: \(error)")
        }
    }
    
    func deleteCategory(_ category: Category) {
        let fetchRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", category.id as CVarArg)
        
        do {
            if let entity = try context.fetch(fetchRequest).first {
                context.delete(entity)
                CoreDataManager.shared.saveContext()
            }
        } catch {
            print("Error deleting category: \(error)")
        }
    }
    
    private func initializeDefaultCategoriesIfNeeded() {
        let defaultCategoryNames = ["Breakfast", "Lunch", "Dinner", "Soups", "Salads", "Desserts", "Beverages"]
        let defaultCategoryOrders: [String: Int32] = [
            "Breakfast": 0,
            "Lunch": 1,
            "Dinner": 2,
            "Desserts": 3,
            "Soups": 4,
            "Salads": 5,
            "Beverages": 6
        ]
        
        let fetchRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        do {
            let existingCategories = try context.fetch(fetchRequest)
            
            for category in existingCategories {
                if category.name == "Main Courses" {
                    category.name = "Lunch"
                    category.order = 1
                }
            }
            
            var seenNames: Set<String> = []
            var duplicatesToDelete: [CategoryEntity] = []
            
            for category in existingCategories {
                let name = category.name
                if seenNames.contains(name) {
                    duplicatesToDelete.append(category)
                } else {
                    seenNames.insert(name)
                    if category.order == 0 && defaultCategoryOrders[name] != nil {
                        category.order = defaultCategoryOrders[name] ?? 0
                    }
                }
            }
            
            for category in existingCategories {
                if let name = category.name as String?,
                   let correctOrder = defaultCategoryOrders[name],
                   category.isDefault {
                    category.order = correctOrder
                }
            }
            
            for duplicate in duplicatesToDelete {
                context.delete(duplicate)
            }
            
            for categoryName in defaultCategoryNames {
                if !seenNames.contains(categoryName) {
                    let order = defaultCategoryOrders[categoryName] ?? 0
                    let category = Category(name: categoryName, isDefault: true, order: order)
                    _ = category.toEntity(in: context)
                }
            }
            
            if context.hasChanges {
                CoreDataManager.shared.saveContext()
            }
        } catch {
            print("Error initializing categories: \(error)")
        }
    }
    
    // MARK: - Recipes
    func getAllRecipes(archived: Bool = false) -> [Recipe] {
        let fetchRequest = NSFetchRequest<RecipeEntity>(entityName: "RecipeEntity")
        fetchRequest.predicate = NSPredicate(format: "isArchived == %@", NSNumber(value: archived))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { Recipe(from: $0) }
        } catch {
            print("Error fetching recipes: \(error)")
            return []
        }
    }
    
    func getRecipes(in category: Category?, archived: Bool = false) -> [Recipe] {
        let fetchRequest = NSFetchRequest<RecipeEntity>(entityName: "RecipeEntity")
        
        var predicates: [NSPredicate] = [NSPredicate(format: "isArchived == %@", NSNumber(value: archived))]
        
        if let category = category {
            predicates.append(NSPredicate(format: "ANY categories.id == %@", category.id as CVarArg))
        }
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { Recipe(from: $0) }
        } catch {
            print("Error fetching recipes: \(error)")
            return []
        }
    }
    
    func searchRecipes(query: String, in category: Category? = nil) -> [Recipe] {
        let fetchRequest = NSFetchRequest<RecipeEntity>(entityName: "RecipeEntity")
        
        var predicates: [NSPredicate] = [
            NSPredicate(format: "isArchived == %@", NSNumber(value: false)),
            NSPredicate(format: "name CONTAINS[cd] %@ OR recipeInstructions CONTAINS[cd] %@", query, query)
        ]
        
        if let category = category {
            predicates.append(NSPredicate(format: "ANY categories.id == %@", category.id as CVarArg))
        }
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { Recipe(from: $0) }
        } catch {
            print("Error searching recipes: \(error)")
            return []
        }
    }
    
    func getRecipe(by id: UUID) -> Recipe? {
        let fetchRequest = NSFetchRequest<RecipeEntity>(entityName: "RecipeEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let entity = try context.fetch(fetchRequest).first {
                return Recipe(from: entity)
            }
        } catch {
            print("Error fetching recipe: \(error)")
        }
        return nil
    }
    
    func saveRecipe(_ recipe: Recipe) {
        _ = recipe.toEntity(in: context)
        CoreDataManager.shared.saveContext()
    }
    
    func deleteRecipe(_ recipe: Recipe) {
        let fetchRequest = NSFetchRequest<RecipeEntity>(entityName: "RecipeEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", recipe.id as CVarArg)
        
        do {
            if let entity = try context.fetch(fetchRequest).first {
                context.delete(entity)
                CoreDataManager.shared.saveContext()
            }
        } catch {
            print("Error deleting recipe: \(error)")
        }
    }
    
    func archiveRecipe(_ recipe: Recipe) {
        var updatedRecipe = recipe
        updatedRecipe.isArchived = true
        saveRecipe(updatedRecipe)
    }
    
    func unarchiveRecipe(_ recipe: Recipe) {
        var updatedRecipe = recipe
        updatedRecipe.isArchived = false
        saveRecipe(updatedRecipe)
    }
    
    // MARK: - Favorites
    func getFavoriteRecipes() -> [Recipe] {
        let fetchRequest = NSFetchRequest<RecipeEntity>(entityName: "RecipeEntity")
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isArchived == %@", NSNumber(value: false)),
            NSPredicate(format: "isFavorite == %@", NSNumber(value: true))
        ])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.compactMap { Recipe(from: $0) }
        } catch {
            print("Error fetching favorite recipes: \(error)")
            return []
        }
    }
    
    func toggleFavorite(_ recipe: Recipe) {
        var updatedRecipe = recipe
        updatedRecipe.isFavorite.toggle()
        saveRecipe(updatedRecipe)
    }
    
    func addToFavorites(_ recipe: Recipe) {
        var updatedRecipe = recipe
        updatedRecipe.isFavorite = true
        saveRecipe(updatedRecipe)
    }
    
    func removeFromFavorites(_ recipe: Recipe) {
        var updatedRecipe = recipe
        updatedRecipe.isFavorite = false
        saveRecipe(updatedRecipe)
    }
    
    // MARK: - Mock Data
    private static func loadImageData(fromAssets name: String) -> Data? {
        if let image = UIImage(named: name),
           let imageData = image.jpegData(compressionQuality: 0.8) {
            return imageData
        }
        
        let imageExtensions = ["jpg", "jpeg", "png"]
        
        for ext in imageExtensions {
            if let imagePath = Bundle.main.path(forResource: name, ofType: ext),
               let image = UIImage(contentsOfFile: imagePath),
               let imageData = image.jpegData(compressionQuality: 0.8) {
                return imageData
            }
        }
        
        return nil
    }
    
    static func mockRecipes() -> [Recipe] {
        let categories = [
            Category(name: "Soups", isDefault: true),
            Category(name: "Desserts", isDefault: true),
            Category(name: "Beverages", isDefault: false),
            Category(name: "Breakfast", isDefault: true)
        ]
        
        return [
            Recipe(
                name: "New York Cheesecake",
                recipeInstructions: "1. Preheat oven to 325°F (165°C).\n2. Mix graham cracker crumbs, melted butter, and sugar. Press into bottom of springform pan.\n3. Beat cream cheese until smooth. Gradually add sugar, then eggs one at a time.\n4. Add vanilla and sour cream. Mix until smooth.\n5. Pour over crust. Bake for 55-60 minutes until center is almost set.\n6. Turn off oven and let cool in oven for 1 hour.\n7. Refrigerate for at least 4 hours before serving.",
                imageData: loadImageData(fromAssets: "1"),
                ingredients: [
                    Ingredient(name: "Graham cracker crumbs", amount: "1 1/2 cups"),
                    Ingredient(name: "Butter", amount: "1/3 cup, melted"),
                    Ingredient(name: "Sugar", amount: "1/4 cup"),
                    Ingredient(name: "Cream cheese", amount: "4 packages (32 oz)"),
                    Ingredient(name: "Sugar", amount: "1 cup"),
                    Ingredient(name: "Eggs", amount: "4 large"),
                    Ingredient(name: "Vanilla extract", amount: "1 tsp"),
                    Ingredient(name: "Sour cream", amount: "1 cup")
                ],
                categories: [categories[1]],
                cookingTime: 60,
                servings: 12,
                difficulty: "medium"
            ),
            Recipe(
                name: "Banana Pancakes",
                recipeInstructions: "1. Mash bananas in a bowl until smooth.\n2. Add eggs, milk, and vanilla. Mix well.\n3. In a separate bowl, combine flour, baking powder, salt, and cinnamon.\n4. Add dry ingredients to wet ingredients. Mix until just combined (don't overmix).\n5. Heat a griddle or pan over medium heat. Grease with butter.\n6. Pour 1/4 cup batter for each pancake.\n7. Cook until bubbles form on top, then flip and cook until golden brown.\n8. Serve with sliced bananas, maple syrup, and butter.",
                imageData: loadImageData(fromAssets: "2"),
                ingredients: [
                    Ingredient(name: "Ripe bananas", amount: "2 large"),
                    Ingredient(name: "Eggs", amount: "2 large"),
                    Ingredient(name: "Milk", amount: "1/2 cup"),
                    Ingredient(name: "Vanilla extract", amount: "1 tsp"),
                    Ingredient(name: "All-purpose flour", amount: "1 cup"),
                    Ingredient(name: "Baking powder", amount: "1 tsp"),
                    Ingredient(name: "Salt", amount: "1/4 tsp"),
                    Ingredient(name: "Cinnamon", amount: "1/2 tsp"),
                    Ingredient(name: "Butter", amount: "for cooking"),
                    Ingredient(name: "Maple syrup", amount: "for serving")
                ],
                categories: [categories[3]],
                cookingTime: 15,
                servings: 4,
                difficulty: "easy"
            ),
            Recipe(
                name: "Moroccan Tea",
                recipeInstructions: "1. Boil water in a teapot.\n2. Add green tea leaves and let steep for 2 minutes.\n3. Add fresh mint leaves.\n4. Add sugar to taste (traditionally 2-3 teaspoons per glass).\n5. Pour tea from height to create foam (this aerates the tea).\n6. Pour back and forth between teapot and glass 2-3 times.\n7. Serve hot in small glasses with mint sprigs.",
                imageData: loadImageData(fromAssets: "3"),
                ingredients: [
                    Ingredient(name: "Green tea", amount: "2 tbsp"),
                    Ingredient(name: "Fresh mint", amount: "1 large bunch"),
                    Ingredient(name: "Sugar", amount: "to taste"),
                    Ingredient(name: "Water", amount: "4 cups")
                ],
                categories: [categories[2]],
                cookingTime: 5,
                servings: 4,
                difficulty: "easy"
            ),
            Recipe(
                name: "Schwarzwald Cake",
                recipeInstructions: "1. Preheat oven to 350°F (175°C). Grease and flour two 9-inch cake pans.\n2. In a bowl, mix flour, cocoa, baking powder, and salt.\n3. Beat eggs and sugar until fluffy. Add vanilla and oil.\n4. Gradually add dry ingredients, then milk. Mix until smooth.\n5. Divide batter between pans. Bake for 25-30 minutes.\n6. Cool completely. Cut each layer in half.\n7. Whip cream with sugar and vanilla.\n8. Layer cake with whipped cream and cherries.\n9. Frost with remaining cream. Decorate with chocolate shavings and cherries.",
                imageData: loadImageData(fromAssets: "4"),
                ingredients: [
                    Ingredient(name: "All-purpose flour", amount: "2 cups"),
                    Ingredient(name: "Cocoa powder", amount: "3/4 cup"),
                    Ingredient(name: "Baking powder", amount: "2 tsp"),
                    Ingredient(name: "Salt", amount: "1/2 tsp"),
                    Ingredient(name: "Eggs", amount: "4 large"),
                    Ingredient(name: "Sugar", amount: "1 1/2 cups"),
                    Ingredient(name: "Vanilla extract", amount: "2 tsp"),
                    Ingredient(name: "Vegetable oil", amount: "1/2 cup"),
                    Ingredient(name: "Milk", amount: "1 cup"),
                    Ingredient(name: "Heavy cream", amount: "2 cups"),
                    Ingredient(name: "Cherries", amount: "1 can (15 oz)"),
                    Ingredient(name: "Dark chocolate", amount: "100 g")
                ],
                categories: [categories[1]],
                cookingTime: 60,
                servings: 12,
                difficulty: "hard"
            ),
            Recipe(
                name: "Russian Borscht",
                recipeInstructions: "1. In a large pot, bring beef and water to a boil. Reduce heat and simmer for 1 hour.\n2. Add beets, carrots, and onions. Cook for 20 minutes.\n3. Add cabbage and potatoes. Cook for 15 minutes.\n4. Add tomato paste, vinegar, and seasonings. Simmer for 10 minutes.\n5. Serve hot with sour cream and fresh dill.",
                imageData: loadImageData(fromAssets: "5"),
                ingredients: [
                    Ingredient(name: "Beef", amount: "500 g"),
                    Ingredient(name: "Beets", amount: "2 medium"),
                    Ingredient(name: "Cabbage", amount: "300 g"),
                    Ingredient(name: "Potatoes", amount: "3 medium"),
                    Ingredient(name: "Carrots", amount: "1 large"),
                    Ingredient(name: "Onion", amount: "1 medium"),
                    Ingredient(name: "Tomato paste", amount: "2 tbsp"),
                    Ingredient(name: "White vinegar", amount: "1 tbsp"),
                    Ingredient(name: "Sour cream", amount: "for serving"),
                    Ingredient(name: "Fresh dill", amount: "for garnish")
                ],
                categories: [categories[0]],
                cookingTime: 90,
                servings: 6,
                difficulty: "medium"
            )
        ]
    }
}


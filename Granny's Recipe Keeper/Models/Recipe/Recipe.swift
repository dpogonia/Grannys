//
//  Recipe.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit
import CoreData

struct Recipe {
    let id: UUID
    
    var name: String
    
    var recipeInstructions: String?
    
    var imageData: Data?
    
    var imageURL: String?
    
    var ingredients: [Ingredient]
    
    var categories: [Category]
    
    var isArchived: Bool
    
    var isFavorite: Bool
    
    var createdAt: Date
    
    var cookingTime: Int?
    
    var servings: Int?
    
    var difficulty: String?
    
    var calories: Int?
    
    var tags: [String]
    
    init(id: UUID = UUID(), name: String, recipeInstructions: String? = nil, imageData: Data? = nil, imageURL: String? = nil, ingredients: [Ingredient] = [], categories: [Category] = [], isArchived: Bool = false, isFavorite: Bool = false, createdAt: Date = Date(), cookingTime: Int? = nil, servings: Int? = nil, difficulty: String? = nil, calories: Int? = nil, tags: [String] = []) {
        self.id = id
        self.name = name
        self.recipeInstructions = recipeInstructions
        self.imageData = imageData
        self.imageURL = imageURL
        self.ingredients = ingredients
        self.categories = categories
        self.isArchived = isArchived
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.cookingTime = cookingTime
        self.servings = servings
        self.difficulty = difficulty
        self.calories = calories
        self.tags = tags
    }
    
    var image: UIImage? {
        if let imageData = imageData {
            return UIImage(data: imageData)
        }
        return nil
    }
}

struct Ingredient {
    let id: UUID
    
    var name: String
    
    var amount: String?
    
    init(id: UUID = UUID(), name: String, amount: String? = nil) {
        self.id = id
        self.name = name
        self.amount = amount
    }
    
    var displayText: String {
        if let amount = amount, !amount.isEmpty {
            return "\(name) - \(amount)"
        }
        return name
    }
}

struct Category {
    let id: UUID
    
    var name: String
    
    var isDefault: Bool
    
    var order: Int32
    
    init(id: UUID = UUID(), name: String, isDefault: Bool = false, order: Int32 = 0) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
        self.order = order
    }
}

extension Recipe {
    init?(from entity: RecipeEntity) {
        self.id = entity.id
        self.name = entity.name
        self.recipeInstructions = entity.recipeInstructions
        self.imageData = entity.imageData
        self.imageURL = entity.imageURL
        self.isArchived = entity.isArchived
        self.isFavorite = entity.isFavorite
        self.createdAt = entity.createdAt
        
        self.cookingTime = entity.cookingTime as? Int
        self.servings = entity.servings as? Int
        self.difficulty = entity.difficulty
        self.calories = entity.calories as? Int
        
        self.tags = entity.tags?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []
        
        if let ingredientsSet = entity.ingredients as? Set<IngredientEntity> {
            self.ingredients = ingredientsSet.compactMap { Ingredient(from: $0) }
        } else {
            self.ingredients = []
        }
        
        if let categoriesSet = entity.categories as? Set<CategoryEntity> {
            self.categories = categoriesSet.compactMap { Category(from: $0) }
        } else {
            self.categories = []
        }
    }
    
    func toEntity(in context: NSManagedObjectContext) -> RecipeEntity {
        let fetchRequest = NSFetchRequest<RecipeEntity>(entityName: "RecipeEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        let recipeEntity: RecipeEntity
        if let existing = try? context.fetch(fetchRequest).first {
            recipeEntity = existing
        } else {
            recipeEntity = RecipeEntity(context: context)
            recipeEntity.id = id
            recipeEntity.createdAt = createdAt
        }
        
        recipeEntity.name = name
        recipeEntity.recipeInstructions = recipeInstructions
        recipeEntity.imageData = imageData
        recipeEntity.imageURL = imageURL
        recipeEntity.isArchived = isArchived
        recipeEntity.isFavorite = isFavorite
        
        recipeEntity.cookingTime = cookingTime as NSNumber?
        recipeEntity.servings = servings as NSNumber?
        recipeEntity.difficulty = difficulty
        recipeEntity.calories = calories as NSNumber?
        
        recipeEntity.tags = tags.isEmpty ? nil : tags.joined(separator: ",")
        
        let ingredientsSet = NSMutableSet()
        
        for ingredient in ingredients {
            let ingredientEntity = ingredient.toEntity(in: context)
            
            ingredientEntity.recipe = recipeEntity
            
            ingredientsSet.add(ingredientEntity)
        }
        
        recipeEntity.ingredients = ingredientsSet
        
        let categoriesSet = NSMutableSet()
        for category in categories {
            if let categoryEntity = Category.fetchOrCreate(category: category, in: context) {
                categoriesSet.add(categoryEntity)
            }
        }
        recipeEntity.categories = categoriesSet
        
        return recipeEntity
    }
}

extension Ingredient {
    init?(from entity: IngredientEntity) {
        self.id = entity.id
        self.name = entity.name
        self.amount = entity.amount
    }
    
    func toEntity(in context: NSManagedObjectContext) -> IngredientEntity {
        let fetchRequest = NSFetchRequest<IngredientEntity>(entityName: "IngredientEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        let ingredientEntity: IngredientEntity
        if let existing = try? context.fetch(fetchRequest).first {
            ingredientEntity = existing
        } else {
            ingredientEntity = IngredientEntity(context: context)
            ingredientEntity.id = id
        }
        
        ingredientEntity.name = name
        ingredientEntity.amount = amount
        
        return ingredientEntity
    }
}

extension Category {
    init?(from entity: CategoryEntity) {
        self.id = entity.id
        self.name = entity.name
        self.isDefault = entity.isDefault
        self.order = entity.order
    }
    
    func toEntity(in context: NSManagedObjectContext) -> CategoryEntity {
        let fetchRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        let categoryEntity: CategoryEntity
        if let existing = try? context.fetch(fetchRequest).first {
            categoryEntity = existing
        } else {
            categoryEntity = CategoryEntity(context: context)
            categoryEntity.id = id
        }
        
        categoryEntity.name = name
        categoryEntity.isDefault = isDefault
        categoryEntity.order = order
        
        return categoryEntity
    }
    
    static func fetchOrCreate(category: Category, in context: NSManagedObjectContext) -> CategoryEntity? {
        let fetchByNameRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        fetchByNameRequest.predicate = NSPredicate(format: "name == %@", category.name)
        
        if let existingByName = try? context.fetch(fetchByNameRequest).first {
            return existingByName
        }
        
        let fetchByIdRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        fetchByIdRequest.predicate = NSPredicate(format: "id == %@", category.id as CVarArg)
        
        if let existingById = try? context.fetch(fetchByIdRequest).first {
            return existingById
        }
        
        return category.toEntity(in: context)
    }
}

// MARK: - Recipe Builder

class RecipeBuilder {
    
    private var id: UUID = UUID()
    private var name: String
    private var recipeInstructions: String?
    private var imageData: Data?
    private var imageURL: String?
    private var ingredients: [Ingredient] = []
    private var categories: [Category] = []
    private var isArchived: Bool = false
    private var isFavorite: Bool = false
    private var createdAt: Date = Date()
    private var cookingTime: Int?
    private var servings: Int?
    private var difficulty: String?
    private var calories: Int?
    private var tags: [String] = []
    
    init(name: String) {
        self.name = name
    }
    
    func with(instructions: String) -> RecipeBuilder {
        self.recipeInstructions = instructions
        return self
    }
    
    // Установить данные изображения
    func with(imageData: Data) -> RecipeBuilder {
        self.imageData = imageData
        return self
    }
    
    // Установить URL изображения
    func with(imageURL: String) -> RecipeBuilder {
        self.imageURL = imageURL
        return self
    }
    
    // Установить время приготовления в минутах
    func with(cookingTime: Int) -> RecipeBuilder {
        self.cookingTime = cookingTime
        return self
    }
    
    // Установить количество порций
    func with(servings: Int) -> RecipeBuilder {
        self.servings = servings
        return self
    }
    
    // Установить уровень сложности (easy, medium, hard)
    func with(difficulty: String) -> RecipeBuilder {
        self.difficulty = difficulty
        return self
    }
    
    // Установить калорийность
    func with(calories: Int) -> RecipeBuilder {
        self.calories = calories
        return self
    }
    
    // Отметить рецепт как избранный
    func markAsFavorite(_ isFavorite: Bool = true) -> RecipeBuilder {
        self.isFavorite = isFavorite
        return self
    }
    
    // Отметить рецепт как архивный
    func markAsArchived(_ isArchived: Bool = true) -> RecipeBuilder {
        self.isArchived = isArchived
        return self
    }
    
    // Установить дату создания
    func with(createdAt: Date) -> RecipeBuilder {
        self.createdAt = createdAt
        return self
    }
    
    // Установить ID (используется при восстановлении существующего рецепта)
    func with(id: UUID) -> RecipeBuilder {
        self.id = id
        return self
    }
    
    
    func addIngredient(_ ingredient: Ingredient) -> RecipeBuilder {
        self.ingredients.append(ingredient)
        return self
    }
    
    func addIngredient(name: String, amount: String? = nil) -> RecipeBuilder {
        let ingredient = Ingredient(name: name, amount: amount)
        self.ingredients.append(ingredient)
        return self
    }
    
    // Добавить несколько ингредиентов
    func addIngredients(_ ingredients: [Ingredient]) -> RecipeBuilder {
        self.ingredients.append(contentsOf: ingredients)
        return self
    }
    
    // Добавить категорию
    func addCategory(_ category: Category) -> RecipeBuilder {
        self.categories.append(category)
        return self
    }
    
    // Добавить несколько категорий
    func addCategories(_ categories: [Category]) -> RecipeBuilder {
        self.categories.append(contentsOf: categories)
        return self
    }
    
    // Добавить тег
    func addTag(_ tag: String) -> RecipeBuilder {
        if !self.tags.contains(tag) {
            self.tags.append(tag)
        }
        return self
    }
    
    // Добавить несколько тегов
    func addTags(_ tags: [String]) -> RecipeBuilder {
        for tag in tags where !self.tags.contains(tag) {
            self.tags.append(tag)
        }
        return self
    }
    
    func build() -> Recipe {
        return Recipe(
            id: id,
            name: name,
            recipeInstructions: recipeInstructions,
            imageData: imageData,
            imageURL: imageURL,
            ingredients: ingredients,
            categories: categories,
            isArchived: isArchived,
            isFavorite: isFavorite,
            createdAt: createdAt,
            cookingTime: cookingTime,
            servings: servings,
            difficulty: difficulty,
            calories: calories,
            tags: tags
        )
    }
}

extension Recipe {
    // Паттерн Prototype позволяет создавать копии существующих объектов без привязки к их конкретным классам. Метод Recipe.builder(from: recipe) принимает существующий рецепт. Создает новый Builder с копией всех свойств оригинального рецепта. Позволяет дальше изменить любые свойства через fluent interface. Финальный вызов .build() создаст новый Recipe.
    static func builder(from recipe: Recipe) -> RecipeBuilder {
        return RecipeBuilder(name: recipe.name)
            .with(id: recipe.id)
            .with(instructions: recipe.recipeInstructions ?? "")
            .with(cookingTime: recipe.cookingTime ?? 0)
            .with(servings: recipe.servings ?? 0)
            .with(difficulty: recipe.difficulty ?? "")
            .with(calories: recipe.calories ?? 0)
            .markAsFavorite(recipe.isFavorite)
            .markAsArchived(recipe.isArchived)
            .with(createdAt: recipe.createdAt)
            .addIngredients(recipe.ingredients)
            .addCategories(recipe.categories)
            .addTags(recipe.tags)
    }
    
    // Создать новый Builder с указанным названием
    static func builder(name: String) -> RecipeBuilder {
        return RecipeBuilder(name: name)
    }
}
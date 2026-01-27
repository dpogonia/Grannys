//
//  CoreDataManager.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

// ДЗ ТЕМА 30: ПОРОЖДАЮЩИЕ ПАТТЕРНЫ. Singleton.

import CoreData
import UIKit

// ДЗ ТЕМА 30: ПОРОЖДАЮЩИЕ ПАТТЕРНЫ
// ПАТТЕРН 1: SINGLETON
// Описание: CoreDataManager реализует паттерн Singleton для обеспечения единственного экземпляра менеджера Core Data во всем приложении. Гарантирует единый контекст Core Data, предотвращает конфликты данных.
class CoreDataManager {
    
    // ПАТТЕРН SINGLETON: Единственный экземпляр класса, доступный глобально
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let model = NSManagedObjectModel()
        
        let recipeEntity = NSEntityDescription()
        recipeEntity.name = "RecipeEntity"
        recipeEntity.managedObjectClassName = NSStringFromClass(RecipeEntity.self)
        
        let recipeId = NSAttributeDescription()
        recipeId.name = "id"
        recipeId.attributeType = .UUIDAttributeType
        recipeId.isOptional = false
        
        let recipeName = NSAttributeDescription()
        recipeName.name = "name"
        recipeName.attributeType = .stringAttributeType
        recipeName.isOptional = false
        
        let recipeInstructions = NSAttributeDescription()
        recipeInstructions.name = "recipeInstructions"
        recipeInstructions.attributeType = .stringAttributeType
        recipeInstructions.isOptional = true
        
        let recipeImageData = NSAttributeDescription()
        recipeImageData.name = "imageData"
        recipeImageData.attributeType = .binaryDataAttributeType
        recipeImageData.isOptional = true
        
        let recipeImageURL = NSAttributeDescription()
        recipeImageURL.name = "imageURL"
        recipeImageURL.attributeType = .stringAttributeType
        recipeImageURL.isOptional = true
        
        let recipeIsArchived = NSAttributeDescription()
        recipeIsArchived.name = "isArchived"
        recipeIsArchived.attributeType = .booleanAttributeType
        recipeIsArchived.isOptional = false
        recipeIsArchived.defaultValue = false
        
        let recipeIsFavorite = NSAttributeDescription()
        recipeIsFavorite.name = "isFavorite"
        recipeIsFavorite.attributeType = .booleanAttributeType
        recipeIsFavorite.isOptional = false
        recipeIsFavorite.defaultValue = false
        
        let recipeCreatedAt = NSAttributeDescription()
        recipeCreatedAt.name = "createdAt"
        recipeCreatedAt.attributeType = .dateAttributeType
        recipeCreatedAt.isOptional = false
        recipeCreatedAt.defaultValue = Date()
        
        let recipeCookingTime = NSAttributeDescription()
        recipeCookingTime.name = "cookingTime"
        recipeCookingTime.attributeType = .integer32AttributeType
        recipeCookingTime.isOptional = true
        
        let recipeServings = NSAttributeDescription()
        recipeServings.name = "servings"
        recipeServings.attributeType = .integer32AttributeType
        recipeServings.isOptional = true
        
        let recipeDifficulty = NSAttributeDescription()
        recipeDifficulty.name = "difficulty"
        recipeDifficulty.attributeType = .stringAttributeType
        recipeDifficulty.isOptional = true
        
        let recipeCalories = NSAttributeDescription()
        recipeCalories.name = "calories"
        recipeCalories.attributeType = .integer32AttributeType
        recipeCalories.isOptional = true
        
        let recipeTags = NSAttributeDescription()
        recipeTags.name = "tags"
        recipeTags.attributeType = .stringAttributeType
        recipeTags.isOptional = true
        
        recipeEntity.properties = [recipeId, recipeName, recipeInstructions, recipeImageData, recipeImageURL, recipeIsArchived, recipeIsFavorite, recipeCreatedAt, recipeCookingTime, recipeServings, recipeDifficulty, recipeCalories, recipeTags]
        
        let categoryEntity = NSEntityDescription()
        categoryEntity.name = "CategoryEntity"
        categoryEntity.managedObjectClassName = NSStringFromClass(CategoryEntity.self)
        
        let categoryId = NSAttributeDescription()
        categoryId.name = "id"
        categoryId.attributeType = .UUIDAttributeType
        categoryId.isOptional = false
        
        let categoryName = NSAttributeDescription()
        categoryName.name = "name"
        categoryName.attributeType = .stringAttributeType
        categoryName.isOptional = false
        
        let categoryIsDefault = NSAttributeDescription()
        categoryIsDefault.name = "isDefault"
        categoryIsDefault.attributeType = .booleanAttributeType
        categoryIsDefault.isOptional = false
        categoryIsDefault.defaultValue = false
        
        let categoryOrder = NSAttributeDescription()
        categoryOrder.name = "order"
        categoryOrder.attributeType = .integer32AttributeType
        categoryOrder.isOptional = false
        categoryOrder.defaultValue = 0
        
        categoryEntity.properties = [categoryId, categoryName, categoryIsDefault, categoryOrder]
        
        let ingredientEntity = NSEntityDescription()
        ingredientEntity.name = "IngredientEntity"
        ingredientEntity.managedObjectClassName = NSStringFromClass(IngredientEntity.self)
        
        let ingredientId = NSAttributeDescription()
        ingredientId.name = "id"
        ingredientId.attributeType = .UUIDAttributeType
        ingredientId.isOptional = false
        
        let ingredientName = NSAttributeDescription()
        ingredientName.name = "name"
        ingredientName.attributeType = .stringAttributeType
        ingredientName.isOptional = false
        
        let ingredientAmount = NSAttributeDescription()
        ingredientAmount.name = "amount"
        ingredientAmount.attributeType = .stringAttributeType
        ingredientAmount.isOptional = true
        
        ingredientEntity.properties = [ingredientId, ingredientName, ingredientAmount]
        
        let appSettingsEntity = NSEntityDescription()
        appSettingsEntity.name = "AppSettingsEntity"
        appSettingsEntity.managedObjectClassName = NSStringFromClass(AppSettingsEntity.self)
        
        let settingsId = NSAttributeDescription()
        settingsId.name = "id"
        settingsId.attributeType = .UUIDAttributeType
        settingsId.isOptional = false
        
        let isSpecialCategoriesHidden = NSAttributeDescription()
        isSpecialCategoriesHidden.name = "isSpecialCategoriesHidden"
        isSpecialCategoriesHidden.attributeType = .booleanAttributeType
        isSpecialCategoriesHidden.isOptional = false
        isSpecialCategoriesHidden.defaultValue = false
        
        appSettingsEntity.properties = [settingsId, isSpecialCategoriesHidden]
        
        let recipeToIngredients = NSRelationshipDescription()
        recipeToIngredients.name = "ingredients"
        recipeToIngredients.destinationEntity = ingredientEntity
        recipeToIngredients.maxCount = 0
        
        recipeToIngredients.deleteRule = .cascadeDeleteRule
        
        let ingredientToRecipe = NSRelationshipDescription()
        ingredientToRecipe.name = "recipe"
        ingredientToRecipe.destinationEntity = recipeEntity
        ingredientToRecipe.maxCount = 1
        
        ingredientToRecipe.deleteRule = .nullifyDeleteRule
        
        recipeToIngredients.inverseRelationship = ingredientToRecipe
        ingredientToRecipe.inverseRelationship = recipeToIngredients
        
        let recipeToCategories = NSRelationshipDescription()
        recipeToCategories.name = "categories"
        recipeToCategories.destinationEntity = categoryEntity
        recipeToCategories.maxCount = 0
        recipeToCategories.deleteRule = .nullifyDeleteRule
        
        let categoryToRecipes = NSRelationshipDescription()
        categoryToRecipes.name = "recipes"
        categoryToRecipes.destinationEntity = recipeEntity
        categoryToRecipes.maxCount = 0
        categoryToRecipes.deleteRule = .nullifyDeleteRule
        
        recipeToCategories.inverseRelationship = categoryToRecipes
        categoryToRecipes.inverseRelationship = recipeToCategories
        
        recipeEntity.properties.append(recipeToIngredients)
        recipeEntity.properties.append(recipeToCategories)
        ingredientEntity.properties.append(ingredientToRecipe)
        categoryEntity.properties.append(categoryToRecipes)
        
        model.entities = [recipeEntity, categoryEntity, ingredientEntity, appSettingsEntity]
        
        let container = NSPersistentContainer(name: "RecipesModel", managedObjectModel: model)
        
        let storeDescription = NSPersistentStoreDescription()
        storeDescription.type = NSSQLiteStoreType
        
        storeDescription.url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("RecipesModel.sqlite")
        
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true
        
        container.persistentStoreDescriptions = [storeDescription]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data store failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - App Settings
    func getAppSettings() -> AppSettingsEntity {
        let context = viewContext
        let fetchRequest: NSFetchRequest<AppSettingsEntity> = AppSettingsEntity.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        if let settings = try? context.fetch(fetchRequest).first {
            return settings
        }
        
        let settings = AppSettingsEntity(context: context)
        settings.id = UUID()
        settings.isSpecialCategoriesHidden = false
        saveContext()
        return settings
    }
    
    func saveSpecialCategoriesHidden(_ hidden: Bool) {
        let settings = getAppSettings()
        settings.isSpecialCategoriesHidden = hidden
        saveContext()
    }
    
    func isSpecialCategoriesHidden() -> Bool {
        return getAppSettings().isSpecialCategoriesHidden
    }
    
    private init() {} // private init() - запрет создания новых экземпляров извне, единственный способ получить экземпляр - через CoreDataManager.shared
}

// MARK: - NSManagedObject Subclasses
@objc(RecipeEntity)
class RecipeEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var recipeInstructions: String?
    @NSManaged var imageData: Data?
    @NSManaged var imageURL: String?
    @NSManaged var isArchived: Bool
    @NSManaged var isFavorite: Bool
    @NSManaged var createdAt: Date
    @NSManaged var cookingTime: NSNumber?
    @NSManaged var servings: NSNumber?
    @NSManaged var difficulty: String?
    @NSManaged var calories: NSNumber?
    @NSManaged var tags: String?
    @NSManaged var ingredients: NSSet?
    @NSManaged var categories: NSSet?
}

@objc(CategoryEntity)
class CategoryEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var isDefault: Bool
    @NSManaged var order: Int32
    @NSManaged var recipes: NSSet?
}

@objc(IngredientEntity)
class IngredientEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var amount: String?
    @NSManaged var recipe: RecipeEntity?
}

@objc(AppSettingsEntity)
class AppSettingsEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var isSpecialCategoriesHidden: Bool
}

extension AppSettingsEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppSettingsEntity> {
        return NSFetchRequest<AppSettingsEntity>(entityName: "AppSettingsEntity")
    }
}


//
//  CoreDataManager.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import CoreData
import UIKit

// MARK: - CoreDataManager
// CoreDataManager - это менеджер базы данных приложения
//
// Core Data как библиотека с картотекой
// - База данных (SQLite файл) - это хранилище с полками
// - Модель данных (NSManagedObjectModel) - это схема картотеки (какие карточки и какие поля)
// - Контекст (NSManagedObjectContext) - это рабочий стол, где ты работаешь с карточками
// - Сохранение (saveContext) - это когда ты кладёшь карточки обратно на полки

class CoreDataManager {
    // Singleton паттерн - один экземпляр на всё приложение
    // Все части приложения используют одну и ту же базу данных
    static let shared = CoreDataManager()
    
    // lazy var - это ленивое свойство: создаётся только при первом обращении
    // Это полезно, потому что создание базы данных - дорогая операция. Мы не хотим создавать её, пока она не понадобится
    // NSPersistentContainer - это контейнер, который управляет всей базой данных
    lazy var persistentContainer: NSPersistentContainer = {
        // Создаем модель данных программно (в коде, а не в файле .xcdatamodeld)
        // Модель - это описание структуры данных: какие таблицы, какие поля
        // Это как чертёж здания: описывает, как устроена база данных
        let model = NSManagedObjectModel()
        
        // Recipe Entity (Сущность Рецепт)
        // Entity - это таблица в базе данных (как таблица в Excel)
        // Каждая строка таблицы - это один рецепт
        let recipeEntity = NSEntityDescription()
        recipeEntity.name = "RecipeEntity"
        // managedObjectClassName - имя класса Swift, который представляет эту сущность
        recipeEntity.managedObjectClassName = NSStringFromClass(RecipeEntity.self)
        
        // Теперь создаём поля (атрибуты) для таблицы RecipeEntity
        // Каждое поле имеет название, тип и может быть обязательным или нет
        
        // Поле "id" - уникальный идентификатор рецепта
        let recipeId = NSAttributeDescription()
        recipeId.name = "id"
        recipeId.attributeType = .UUIDAttributeType // Тип: UUID (уникальный идентификатор)
        recipeId.isOptional = false // Обязательное поле (не может быть пустым)
        
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
        recipeCookingTime.name = "cookingTime" // будет добавлено в будущем
        recipeCookingTime.attributeType = .integer32AttributeType
        recipeCookingTime.isOptional = true
        
        let recipeServings = NSAttributeDescription()
        recipeServings.name = "servings" // будет добавлено в будущем
        recipeServings.attributeType = .integer32AttributeType
        recipeServings.isOptional = true
        
        let recipeDifficulty = NSAttributeDescription()
        recipeDifficulty.name = "difficulty"
        recipeDifficulty.attributeType = .stringAttributeType
        recipeDifficulty.isOptional = true
        
        let recipeCalories = NSAttributeDescription()
        recipeCalories.name = "calories" // будет добавлено в будущем
        recipeCalories.attributeType = .integer32AttributeType
        recipeCalories.isOptional = true
        
        let recipeTags = NSAttributeDescription()
        recipeTags.name = "tags"
        recipeTags.attributeType = .stringAttributeType
        recipeTags.isOptional = true
        
        recipeEntity.properties = [recipeId, recipeName, recipeInstructions, recipeImageData, recipeImageURL, recipeIsArchived, recipeIsFavorite, recipeCreatedAt, recipeCookingTime, recipeServings, recipeDifficulty, recipeCalories, recipeTags]
        
        // Category Entity
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
        
        // Ingredient Entity
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
        
        // AppSettings Entity
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
        
        // Relationships (Связи между сущностями)
        // Связи - это как связи между таблицами в базе данных
        // АНАЛОГИЯ: Как связи в семье - рецепт "имеет" ингредиенты, ингредиент "принадлежит" рецепту
        
        // Связь от Recipe к Ingredient (один ко многим)
        // Один рецепт может иметь много ингредиентов
        let recipeToIngredients = NSRelationshipDescription()
        recipeToIngredients.name = "ingredients"
        recipeToIngredients.destinationEntity = ingredientEntity // Куда ведёт связь
        recipeToIngredients.maxCount = 0 // 0 означает "неограниченное количество" (много)
        
        // deleteRule - правило удаления: что делать с ингредиентами, когда удаляется рецепт
        // .cascadeDeleteRule - каскадное удаление: если удаляем рецепт, удаляются и все его ингредиенты
        // АНАЛОГИЯ: Как удаление папки - удаляются и все файлы внутри
        recipeToIngredients.deleteRule = .cascadeDeleteRule
        
        // Обратная связь: от Ingredient к Recipe (многие к одному)
        // Много ингредиентов могут принадлежать одному рецепту
        let ingredientToRecipe = NSRelationshipDescription()
        ingredientToRecipe.name = "recipe"
        ingredientToRecipe.destinationEntity = recipeEntity
        ingredientToRecipe.maxCount = 1 // Максимум 1 рецепт (один ингредиент принадлежит одному рецепту)
        
        // .nullifyDeleteRule - обнуление связи: если удаляем ингредиент, просто убираем связь с рецептом
        // Рецепт остаётся, но ингредиент больше не связан с ним
        // АНАЛОГИЯ: Как удаление сотрудника - компания остаётся, но сотрудника в ней больше нет
        ingredientToRecipe.deleteRule = .nullifyDeleteRule
        
        // Устанавливаем обратные связи (bidirectional relationship)
        // Это нужно, чтобы Core Data знал, что это одна и та же связь с двух сторон
        // АНАЛОГИЯ: Как двусторонняя улица - можно идти в обе стороны
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
        
        // Создаем контейнер с нашей моделью
        // NSPersistentContainer - это главный объект, который управляет базой данных
        // name: "RecipesModel" - имя базы данных (используется для поиска файла)
        let container = NSPersistentContainer(name: "RecipesModel", managedObjectModel: model)
        
        // Настраиваем, где хранить базу данных
        let storeDescription = NSPersistentStoreDescription()
        // type - тип хранилища: SQLite (файловая база данных)
        storeDescription.type = NSSQLiteStoreType
        
        // url - путь к файлу базы данных на диске
        // .documentDirectory - папка Documents приложения (данные сохраняются между запусками)
        // appendingPathComponent - добавляем имя файла "RecipesModel.sqlite"
        storeDescription.url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("RecipesModel.sqlite")
        
        // Автоматическая миграция: если структура базы изменилась, Core Data обновит её автоматически
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true
        
        // Применяем настройки к контейнеру
        container.persistentStoreDescriptions = [storeDescription]
        
        // Загружаем базу данных (открываем файл)
        // Это асинхронная операция: может занять время, поэтому используется замыкание
        container.loadPersistentStores { description, error in
            if let error = error {
                // Если не удалось загрузить базу данных, приложение не может работать
                // fatalError останавливает приложение с сообщением об ошибке
                fatalError("Core Data store failed to load: \(error.localizedDescription)")
            }
        }
        
        // Автоматически объединять изменения из родительского контекста
        // Это нужно для многопоточности: если данные изменились в фоне, они появятся в UI
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    // viewContext - это главный контекст для работы с данными в UI потоке
    // Контекст - это "рабочая область": все изменения делаются в контексте,
    // а потом сохраняются в базу данных через saveContext()
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // Сохранить все изменения в базу данных
    func saveContext() {
        let context = persistentContainer.viewContext
        
        // Проверяем, есть ли изменения для сохранения
        // Если ничего не меняли, сохранять не нужно
        if context.hasChanges {
            do {
                // try - может выбросить ошибку, поэтому используем do-catch
                // save() - сохраняет все изменения в базу данных
                try context.save()
            } catch {
                // Если сохранение не удалось, выводим ошибку
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
        
        // Создаем новые настройки, если их нет
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
    
    private init() {}
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


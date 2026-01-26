//
//  Recipe.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit
import CoreData

// MARK: - Recipe
// struct - это структура данных, как форма для заполнения
// Recipe описывает, как выглядит рецепт в нашем приложении
// Представь её как карточку рецепта: на ней есть название, ингредиенты, инструкции и т.д.
struct Recipe {
    // let - константа, её нельзя изменить после создания
    // UUID - это уникальный идентификатор (как серийный номер)
    // Каждый рецепт имеет свой уникальный ID, чтобы мы могли его найти среди тысяч других
    let id: UUID
    
    // var - переменная, её можно изменить
    // String - это текст (например, "Борщ")
    var name: String
    
    // String? - это опциональный String (может быть текстом или nil - ничего)
    // Знак ? означает "может отсутствовать"
    // recipeInstructions может быть, а может и не быть (некоторые рецепты без инструкций)
    var recipeInstructions: String?
    
    // Data? - данные изображения в бинарном формате
    // Когда мы сохраняем фото рецепта, оно превращается в набор байтов (Data)
    var imageData: Data?
    
    // Ссылка на изображение в интернете (если рецепт загружен из сети)
    var imageURL: String?
    
    // [Ingredient] - это массив ингредиентов
    // Массив - это список элементов одного типа, как список покупок
    // ingredients - это список всех ингредиентов для рецепта
    var ingredients: [Ingredient]
    
    // Массив категорий (например, ["Завтрак", "Десерты"])
    var categories: [Category]
    
    // Bool - это логический тип: true (да) или false (нет)
    // isArchived - находится ли рецепт в архиве (скрыт, но не удалён)
    var isArchived: Bool
    
    // Помечен ли рецепт как избранный (пользователь добавил его в избранное)
    var isFavorite: Bool
    
    // Date - дата и время создания рецепта
    // Когда пользователь создал этот рецепт
    var createdAt: Date
    
    // Int? - опциональное целое число (может быть числом или nil)
    // Время приготовления в минутах (например, 30 минут)
    var cookingTime: Int?
    
    // Количество порций (например, на 4 человек)
    var servings: Int?
    
    // Сложность приготовления: "легко", "средне", "сложно"
    var difficulty: String?
    
    // Калорийность блюда
    var calories: Int?
    
    // Массив тегов (меток) для фильтрации
    // Например: ["вегетарианский", "без глютена", "быстро"]
    var tags: [String]
    
    // init - это инициализатор, функция, которая создаёт новый рецепт
    // Все параметры имеют значения по умолчанию (=), поэтому можно создать рецепт с минимальными данными
    // Например: Recipe(name: "Борщ") - создаст рецепт только с именем, остальное будет по умолчанию
    init(id: UUID = UUID(), name: String, recipeInstructions: String? = nil, imageData: Data? = nil, imageURL: String? = nil, ingredients: [Ingredient] = [], categories: [Category] = [], isArchived: Bool = false, isFavorite: Bool = false, createdAt: Date = Date(), cookingTime: Int? = nil, servings: Int? = nil, difficulty: String? = nil, calories: Int? = nil, tags: [String] = []) {
        // self - это ссылка на сам объект (на этот конкретный рецепт)
        // self.id = id означает: "установи ID этого рецепта равным переданному ID"
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
    
    // Это computed property (вычисляемое свойство) - оно не хранит значение, а вычисляет его каждый раз при обращении
    // var image: UIImage? - это свойство, которое возвращает изображение из imageData
    // Если у рецепта есть imageData, мы превращаем его в UIImage (картинку для показа на экране)
    var image: UIImage? {
        // if let - это безопасная проверка опционала
        // "Если imageData не nil, то создай константу imageData и используй её"
        if let imageData = imageData {
            // UIImage(data:) превращает бинарные данные в изображение
            return UIImage(data: imageData)
        }
        // Если imageData нет, возвращаем nil (ничего)
        return nil
    }
}

// MARK: - Ingredient
// Ingredient (Ингредиент) - это один ингредиент рецепта
// Например: "Мука - 200 грамм" или просто "Соль"
struct Ingredient {
    // Уникальный идентификатор ингредиента
    let id: UUID
    
    // Название ингредиента (например, "Мука", "Яйца", "Молоко")
    var name: String
    
    // Количество (например, "200 грамм", "2 штуки", "1 стакан")
    // Опциональное, потому что можно указать только название без количества
    var amount: String?
    
    // Инициализатор для создания нового ингредиента
    init(id: UUID = UUID(), name: String, amount: String? = nil) {
        self.id = id
        self.name = name
        self.amount = amount
    }
    
    // Вычисляемое свойство для отображения ингредиента в списке
    // Оно форматирует текст: если есть количество, показывает "Название - Количество"
    // Если количества нет, показывает только название
    var displayText: String {
        // Проверяем: если amount не nil И не пустая строка
        // !amount.isEmpty означает "amount не пустой"
        if let amount = amount, !amount.isEmpty {
            // \(name) - это строковая интерполяция: подставляет значение переменной в строку
            // Результат: "Мука - 200 грамм"
            return "\(name) - \(amount)"
        }
        // Если количества нет, возвращаем только название
        return name
    }
}

// MARK: - Category
// Category (Категория) - это группа, к которой относится рецепт
// Например: "Завтрак", "Обед", "Десерты", "Супы"
// Категории помогают организовать рецепты, как папки в компьютере
struct Category {
    // Уникальный идентификатор категории
    let id: UUID
    
    // Название категории (например, "Завтрак")
    var name: String
    
    // Является ли категория стандартной (созданной системой) или пользовательской
    // true - стандартная (например, "Завтрак", "Обед")
    // false - создана пользователем (например, "Мои любимые")
    var isDefault: Bool
    
    // Порядок отображения категории в списке
    // Чем меньше число, тем выше в списке будет категория
    // Int32 - это целое число (32 бита)
    var order: Int32
    
    // Инициализатор для создания новой категории
    init(id: UUID = UUID(), name: String, isDefault: Bool = false, order: Int32 = 0) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
        self.order = order
    }
}

// MARK: - Core Data Extensions
// Extension - это расширение, которое добавляет новые возможности к существующему типу
// Здесь мы добавляем методы для преобразования между Recipe (наша структура) и RecipeEntity (объект Core Data)

// Почему нужны преобразования?
// Recipe - это простая структура Swift, удобная для работы в коде
// RecipeEntity - это объект Core Data, который умеет сохраняться в базу данных
// Мы используем Recipe в приложении, а для сохранения преобразуем в RecipeEntity

extension Recipe {
    // init?(from:) - это failable initializer (может вернуть nil)
    // Знак ? после init означает, что инициализация может не удаться
    // Преобразует RecipeEntity (из базы данных) в Recipe (для использования в коде)
    // Это как переводчик: переводит данные из формата базы данных в формат приложения
    init?(from entity: RecipeEntity) {
        // Копируем все простые свойства из entity в наш Recipe
        self.id = entity.id
        self.name = entity.name
        self.recipeInstructions = entity.recipeInstructions
        self.imageData = entity.imageData
        self.imageURL = entity.imageURL
        self.isArchived = entity.isArchived
        self.isFavorite = entity.isFavorite
        self.createdAt = entity.createdAt
        
        // as? - безопасное приведение типа
        // Core Data хранит числа как NSNumber, а нам нужен Int
        // Если преобразование не удастся, вернётся nil
        self.cookingTime = entity.cookingTime as? Int
        self.servings = entity.servings as? Int
        self.difficulty = entity.difficulty
        self.calories = entity.calories as? Int
        
        // Теги хранятся в Core Data как одна строка через запятую: "вегетарианский,без глютена"
        // В Swift мы хотим массив: ["вегетарианский", "без глютена"]
        
        // Разберём эту строку по шагам:
        // 1. entity.tags? - опциональная цепочка: если tags = nil, всё выражение вернёт nil
        // 2. components(separatedBy: ",") - разбивает строку на массив по запятой
        //    Пример: "a,b,c" -> ["a", "b", "c"]
        // 3. filter { !$0.isEmpty } - фильтрует массив, оставляя только непустые строки
        //    $0 - это сокращение для первого параметра замыкания (каждый элемент массива)
        //    !$0.isEmpty означает "элемент не пустой"
        //    Пример: ["a", "", "b"] -> ["a", "b"]
        // 4. ?? [] - nil coalescing operator (оператор объединения с nil)
        //    Если слева nil, используем значение справа (пустой массив)
        //    АНАЛОГИЯ: "Если нет тегов, используй пустой список"
        self.tags = entity.tags?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []
        
        // Загружаем ингредиенты из базы данных
        // Set - это коллекция уникальных элементов (как множество в математике)
        // В Set не может быть дубликатов - каждый элемент уникален
        
        // as? - безопасное приведение типа (optional cast)
        // Проверяем: является ли entity.ingredients Set<IngredientEntity>?
        // Если да - создаём константу ingredientsSet
        // Если нет - if let не выполнится, и мы перейдём в else
        if let ingredientsSet = entity.ingredients as? Set<IngredientEntity> {
            // compactMap - это HIGH-ORDER FUNCTION (функция высшего порядка)
            // Она принимает замыкание и применяет его к каждому элементу коллекции
            
            // Разница между map и compactMap:
            // - map: преобразует все элементы, может вернуть nil в массиве [Ingredient?]
            // - compactMap: преобразует элементы и автоматически убирает nil, возвращает [Ingredient]
            
            // { Ingredient(from: $0) } - это замыкание (closure)
            // $0 - это сокращение для первого параметра (каждый IngredientEntity из Set)
            // Ingredient(from:) - это failable initializer, может вернуть nil
            // compactMap пропустит все nil и вернёт только успешно созданные Ingredient
            
            // АНАЛОГИЯ: Как фильтр для воды - пропускает только чистую воду, грязь остаётся
            self.ingredients = ingredientsSet.compactMap { Ingredient(from: $0) }
        } else {
            // Если ингредиентов нет (nil) или неправильный тип, создаём пустой массив
            self.ingredients = []
        }
        
        // Загружаем категории аналогично ингредиентам
        if let categoriesSet = entity.categories as? Set<CategoryEntity> {
            self.categories = categoriesSet.compactMap { Category(from: $0) }
        } else {
            self.categories = []
        }
    }
    
    // Преобразует Recipe (из кода) в RecipeEntity (для сохранения в базу данных)
    // Это обратное преобразование: из формата приложения в формат базы данных
    // context - это "рабочая область" Core Data, где происходят все операции с данными
    func toEntity(in context: NSManagedObjectContext) -> RecipeEntity {
        // Создаём запрос к базе данных: "Найди RecipeEntity с таким ID"
        let fetchRequest = NSFetchRequest<RecipeEntity>(entityName: "RecipeEntity")
        // predicate - это условие поиска (как WHERE в SQL)
        // "id == %@" означает "ID равен переданному значению"
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        // Проверяем, существует ли уже такой рецепт в базе данных
        let recipeEntity: RecipeEntity
        // try? - безопасный вызов: если произойдёт ошибка, вернётся nil
        // .first - берём первый результат (если есть)
        if let existing = try? context.fetch(fetchRequest).first {
            // Рецепт уже существует - обновляем его
            recipeEntity = existing
        } else {
            // Рецепта нет - создаём новый
            recipeEntity = RecipeEntity(context: context)
            recipeEntity.id = id
            recipeEntity.createdAt = createdAt
        }
        
        // Обновляем все свойства рецепта
        recipeEntity.name = name
        recipeEntity.recipeInstructions = recipeInstructions
        recipeEntity.imageData = imageData
        recipeEntity.imageURL = imageURL
        recipeEntity.isArchived = isArchived
        recipeEntity.isFavorite = isFavorite
        
        // Преобразуем Int в NSNumber (Core Data требует NSNumber для чисел)
        recipeEntity.cookingTime = cookingTime as NSNumber?
        recipeEntity.servings = servings as NSNumber?
        recipeEntity.difficulty = difficulty
        recipeEntity.calories = calories as NSNumber?
        
        // Преобразуем массив тегов в строку через запятую
        // joined(separator: ",") - соединяет элементы массива запятыми
        // Если массив пустой, сохраняем nil
        recipeEntity.tags = tags.isEmpty ? nil : tags.joined(separator: ",")
        
        // Сохраняем ингредиенты
        // NSMutableSet - это изменяемое множество (можно добавлять и удалять элементы)
        // Set - это коллекция уникальных элементов (как множество в математике)
        // Mutable означает "изменяемый" (можно менять после создания)
        // В отличие от обычного Set, NSMutableSet можно изменять
        let ingredientsSet = NSMutableSet()
        
        // for-in цикл - проходим по каждому элементу массива
        // АНАЛОГИЯ: Как перебирать карточки в колоде - берём каждую по очереди
        for ingredient in ingredients {
            // Преобразуем Ingredient (наша структура) в IngredientEntity (объект Core Data)
            let ingredientEntity = ingredient.toEntity(in: context)
            
            // Связываем ингредиент с рецептом (устанавливаем связь)
            // Это устанавливает обратную связь: ингредиент знает, к какому рецепту он принадлежит
            ingredientEntity.recipe = recipeEntity
            
            // Добавляем ингредиент в множество
            // add - добавляет элемент в Set (если уже есть, не добавит дубликат)
            ingredientsSet.add(ingredientEntity)
        }
        
        // Сохраняем множество ингредиентов в рецепт
        // Теперь recipeEntity знает обо всех своих ингредиентах
        recipeEntity.ingredients = ingredientsSet
        
        // Сохраняем категории аналогично ингредиентам
        let categoriesSet = NSMutableSet()
        for category in categories {
            // fetchOrCreate - находит существующую категорию или создаёт новую
            // Это нужно, чтобы не создавать дубликаты категорий
            if let categoryEntity = Category.fetchOrCreate(category: category, in: context) {
                categoriesSet.add(categoryEntity)
            }
        }
        recipeEntity.categories = categoriesSet
        
        // Возвращаем готовый RecipeEntity для сохранения в базу данных
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
        // Сначала ищем по имени (чтобы избежать дубликатов)
        let fetchByNameRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        fetchByNameRequest.predicate = NSPredicate(format: "name == %@", category.name)
        
        if let existingByName = try? context.fetch(fetchByNameRequest).first {
            return existingByName
        }
        
        // Если не найдено по имени, ищем по UUID
        let fetchByIdRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        fetchByIdRequest.predicate = NSPredicate(format: "id == %@", category.id as CVarArg)
        
        if let existingById = try? context.fetch(fetchByIdRequest).first {
            return existingById
        }
        
        // Если не найдено ни по имени, ни по UUID, создаем новую
        return category.toEntity(in: context)
    }
}


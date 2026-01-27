//
//  RecipeAdapters.swift
//  Granny's Recipe Keeper
//
//  Created by Dmitrii Pogonia on 26.01.2026.
//

// ДЗ ТЕМА 31: Структурные паттерны. Адаптер.

import Foundation
import UIKit

// MARK: - ДОМАШНЕЕ ЗАДАНИЕ ТЕМА 31: СТРУКТУРНЫЕ ПАТТЕРНЫ
// ПАТТЕРН 2: ADAPTER (АДАПТЕР)
// Описание: Адаптер - структурный паттерн, который позволяет объектам с несовместимыми интерфейсами
//          работать вместе. Адаптер оборачивает объект и предоставляет ему новый интерфейс.
// В приложении используются разные источники данных о рецептах:
//          - TheMealDB API (возвращает TheMealDBRecipe)
//          - Generic Recipe API (возвращает APIRecipe)
//          - Каждое API имеет свою структуру данных
//          - Приложение работает с единой моделью Recipe
//
// Создаю адаптеры, которые преобразуют данные из разных API в единый формат Recipe
//          1. RecipeAdapter - протокол для всех адаптеров
//          2. TheMealDBRecipeAdapter - адаптер для TheMealDB API
//          3. GenericRecipeAdapter - адаптер для Generic Recipe API
//          - Единый интерфейс для работы с разными источниками данных
//          - Легко добавлять новые источники данных (новый адаптер)
//          - Разделение логики преобразования данных
//          - Соответствие Single Responsibility Principle


/// ПАТТЕРН ADAPTER: Протокол для всех адаптеров рецептов определяет единый интерфейс для преобразования данных из разных источников в Recipe
protocol RecipeAdapter {
    /// Преобразует данные из источника в объект Recipe
    func adapt() -> Recipe
    
    /// Преобразует данные из источника в объект Recipe с дополнительными категориями
    func adapt(with categories: [Category]) -> Recipe
}

// MARK: - TheMealDBRecipeAdapter

// ПАТТЕРН ADAPTER: Адаптер для преобразования TheMealDBRecipe в Recipe
// TheMealDB API возвращает данные в специфичном формате (strMeal, strInstructions, strIngredient)
// Этот адаптер преобразует их в единый формат Recipe приложения
class TheMealDBRecipeAdapter: RecipeAdapter {
    
    // ПАТТЕРН ADAPTER: Адаптируемый объект
    private let mealDBRecipe: TheMealDBRecipe
    
    
    // mealDBRecipe: Рецепт из TheMealDB API
    init(mealDBRecipe: TheMealDBRecipe) {
        self.mealDBRecipe = mealDBRecipe
    }
    
    // Метод адаптации без категорий
    func adapt() -> Recipe {
        return adapt(with: [])
    }
    
    // ПАТТЕРН ADAPTER: Основной метод адаптации с категориями. Преобразует сложную структуру TheMealDB (20 полей для ингредиентов) в простой массив
    func adapt(with categories: [Category]) -> Recipe {
        // Преобразование инструкций
        let instructions = mealDBRecipe.strInstructions
        
        // Преобразование ингредиентов из 20 отдельных полей в массив
        let ingredients = extractIngredients()
        
        // Преобразование тегов из строки в массив
        let tags = extractTags()
        
        // Создание Recipe с преобразованными данными
        return RecipeBuilder(name: mealDBRecipe.strMeal ?? "Unknown Recipe")
            .with(instructions: instructions ?? "")
            .with(imageURL: mealDBRecipe.strMealThumb ?? "")
            .addIngredients(ingredients)
            .addCategories(categories)
            .addTags(tags)
            .build()
    }
    
    // MARK: - Private Helper Methods
    
    // ПАТТЕРН ADAPTER: Извлечение ингредиентов из 20 полей API
    // Адаптер преобразует ингредиенты в массив Ingredient
    private func extractIngredients() -> [Ingredient] {
        var ingredients: [Ingredient] = []
        
        let ingredientPairs: [(String?, String?)] = [
            (mealDBRecipe.strIngredient1, mealDBRecipe.strMeasure1),
            (mealDBRecipe.strIngredient2, mealDBRecipe.strMeasure2),
            (mealDBRecipe.strIngredient3, mealDBRecipe.strMeasure3),
            (mealDBRecipe.strIngredient4, mealDBRecipe.strMeasure4),
            (mealDBRecipe.strIngredient5, mealDBRecipe.strMeasure5),
            (mealDBRecipe.strIngredient6, mealDBRecipe.strMeasure6),
            (mealDBRecipe.strIngredient7, mealDBRecipe.strMeasure7),
            (mealDBRecipe.strIngredient8, mealDBRecipe.strMeasure8),
            (mealDBRecipe.strIngredient9, mealDBRecipe.strMeasure9),
            (mealDBRecipe.strIngredient10, mealDBRecipe.strMeasure10),
            (mealDBRecipe.strIngredient11, mealDBRecipe.strMeasure11),
            (mealDBRecipe.strIngredient12, mealDBRecipe.strMeasure12),
            (mealDBRecipe.strIngredient13, mealDBRecipe.strMeasure13),
            (mealDBRecipe.strIngredient14, mealDBRecipe.strMeasure14),
            (mealDBRecipe.strIngredient15, mealDBRecipe.strMeasure15),
            (mealDBRecipe.strIngredient16, mealDBRecipe.strMeasure16),
            (mealDBRecipe.strIngredient17, mealDBRecipe.strMeasure17),
            (mealDBRecipe.strIngredient18, mealDBRecipe.strMeasure18),
            (mealDBRecipe.strIngredient19, mealDBRecipe.strMeasure19),
            (mealDBRecipe.strIngredient20, mealDBRecipe.strMeasure20)
        ]
        
        // ПАТТЕРН ADAPTER: Преобразование каждой пары в объект Ingredient
        for (ingredientName, measure) in ingredientPairs {
            guard let name = ingredientName?.trimmingCharacters(in: .whitespaces),
                  !name.isEmpty else {
                continue
            }
            
            let amount = measure?.trimmingCharacters(in: .whitespaces)
            ingredients.append(Ingredient(name: name, amount: amount))
        }
        
        return ingredients
    }
    
    // ПАТТЕРН ADAPTER: Извлечение тегов из строки с разделителями
    // TheMealDB возвращает теги как строку "Dessert,Sweet,Baking"
    // Адаптер преобразует их в массив ["Dessert", "Sweet", "Baking"]
    private func extractTags() -> [String] {
        guard let tagsString = mealDBRecipe.strTags, !tagsString.isEmpty else {
            return []
        }
        
        return tagsString
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

// ПАТТЕРН ADAPTER: Адаптер для преобразования APIRecipe в Recipe
// Generic Recipe API возвращает данные в другом формате (title, extendedIngredients)
// Этот адаптер преобразует их в единый формат Recipe приложения
class GenericRecipeAdapter: RecipeAdapter {
    
    // ПАТТЕРН ADAPTER: Адаптируемый объект
    private let apiRecipe: APIRecipe
    
    // Инициализатор адаптера
    init(apiRecipe: APIRecipe) {
        self.apiRecipe = apiRecipe
    }
    
    // ПАТТЕРН ADAPTER: Метод адаптации без категорий
    func adapt() -> Recipe {
        return adapt(with: [])
    }
    
    // ПАТТЕРН ADAPTER: Основной метод адаптации с категориями
    // Преобразует структуру APIRecipe в Recipe
    func adapt(with categories: [Category]) -> Recipe {
        let instructions = apiRecipe.instructions ?? apiRecipe.summary ?? ""
        
        // Преобразование ингредиентов из APIIngredient в Ingredient
        let ingredients = extractIngredients()
        
        // Создание Recipe с преобразованными данными
        return RecipeBuilder(name: apiRecipe.title)
            .with(instructions: instructions)
            .with(imageURL: apiRecipe.image ?? "")
            .with(cookingTime: apiRecipe.cookingTime ?? 0)
            .with(servings: apiRecipe.servings ?? 0)
            .with(difficulty: apiRecipe.difficulty ?? "medium")
            .with(calories: apiRecipe.calories ?? 0)
            .addIngredients(ingredients)
            .addCategories(categories)
            .addTags(apiRecipe.tags ?? [])
            .build()
    }
    
    // ПАТТЕРН ADAPTER: Преобразование ингредиентов из API формата в формат приложения
    // APIIngredient имеет поля amount (Double) и unit (String)
    // Ingredient имеет поле amount (String)
    // Адаптер объединяет amount и unit в одну строку
    private func extractIngredients() -> [Ingredient] {
        guard let apiIngredients = apiRecipe.extendedIngredients else {
            return []
        }
        
        return apiIngredients.map { apiIngredient in
            var amountString = ""
            if let amount = apiIngredient.amount {
                let formattedAmount = amount.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", amount)
                : String(format: "%.1f", amount)
                
                // Объединение количества и единицы измерения
                if let unit = apiIngredient.unit, !unit.isEmpty {
                    amountString = "\(formattedAmount) \(unit)"
                } else {
                    amountString = formattedAmount
                }
            }
            
            return Ingredient(name: apiIngredient.name, amount: amountString.isEmpty ? nil : amountString)
        }
    }
}

// Фабрика для создания адаптеров
// Упрощает создание правильного адаптера в зависимости от типа данных
class RecipeAdapterFactory {
    
    // ПАТТЕРН ADAPTER: Создание адаптера для TheMealDB рецепта
    // Адаптер для преобразования в Recipe
    static func makeAdapter(from mealDBRecipe: TheMealDBRecipe) -> RecipeAdapter {
        return TheMealDBRecipeAdapter(mealDBRecipe: mealDBRecipe)
    }
    
    // ПАТТЕРН ADAPTER: Создание адаптера для Generic рецепта
    // apiRecipe: Рецепт из Generic API
    // Адаптер для преобразования в Recipe
    static func makeAdapter(from apiRecipe: APIRecipe) -> RecipeAdapter {
        return GenericRecipeAdapter(apiRecipe: apiRecipe)
    }
}

extension TheMealDBRecipe {
    // метод для преобразования в Recipe
    func toRecipe(with categories: [Category] = []) -> Recipe {
        let adapter = TheMealDBRecipeAdapter(mealDBRecipe: self)
        return adapter.adapt(with: categories)
    }
}

extension APIRecipe {
    // метод для преобразования в Recipe
    func toRecipe(with categories: [Category] = []) -> Recipe {
        let adapter = GenericRecipeAdapter(apiRecipe: self)
        return adapter.adapt(with: categories)
    }
}

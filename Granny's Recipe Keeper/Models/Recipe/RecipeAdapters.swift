//
//  RecipeAdapters.swift
//  Granny's Recipe Keeper
//
//  Created by Dmitrii Pogonia on 26.01.2026.
//

import Foundation
import UIKit

protocol RecipeAdapter {
    func adapt() -> Recipe
    
    func adapt(with categories: [Category]) -> Recipe
}

class TheMealDBRecipeAdapter: RecipeAdapter {
    
    private let mealDBRecipe: TheMealDBRecipe
    
    
    // mealDBRecipe: Рецепт из TheMealDB API
    init(mealDBRecipe: TheMealDBRecipe) {
        self.mealDBRecipe = mealDBRecipe
    }
    
    // Метод адаптации без категорий
    func adapt() -> Recipe {
        return adapt(with: [])
    }
    
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
    
    private let apiRecipe: APIRecipe
    
    // Инициализатор адаптера
    init(apiRecipe: APIRecipe) {
        self.apiRecipe = apiRecipe
    }
    
    func adapt() -> Recipe {
        return adapt(with: [])
    }
    
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
            .addSources(apiRecipe.sources ?? [])
            .build()
    }
    
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
    
    // Адаптер для преобразования в Recipe
    static func makeAdapter(from mealDBRecipe: TheMealDBRecipe) -> RecipeAdapter {
        return TheMealDBRecipeAdapter(mealDBRecipe: mealDBRecipe)
    }
    
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

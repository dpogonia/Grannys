import Foundation

enum CategoryLocalization {
    
    private static let baseCategoryTranslations: [String: String] = [
        "Breakfast": "Завтрак",
        "Lunch": "Обед",
        "Dinner": "Ужин",
        "Soups": "Супы",
        "Salads": "Салаты",
        "Desserts": "Десерты",
        "Beverages": "Напитки",
        "Favorites": "Избранное",
        "Archive": "Архив",
        "All Recipes": "Все рецепты"
    ]
    
    private static let mealDBCategoryTranslations: [String: String] = [
        "Starter": "Закуски",
        "Breakfast": "Завтрак",
        "Main": "Основные блюда",
        "Seafood": "Морепродукты",
        "Side": "Гарниры",
        "Dessert": "Десерты",
        "Miscellaneous": "Разное",
        "Vegan": "Веганские",
        "Vegetarian": "Вегетарианские",
        "Beverage": "Напитки",
        "Shuffle": "Случайно",
        "All Recipes": "Все рецепты"
    ]
    
    static func localizedBaseCategoryName(_ name: String) -> String {
        let uiLang = LocalizationManager.shared.currentLanguage
        guard uiLang == .russian else { return name }
        return baseCategoryTranslations[name] ?? name
    }
    
    static func localizedMealDBCategoryName(_ name: String) -> String {
        let uiLang = LocalizationManager.shared.currentLanguage
        guard uiLang == .russian else { return name }
        return mealDBCategoryTranslations[name] ?? name
    }
}


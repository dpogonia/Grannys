//
//  TheMealDBIngredientCategorizer.swift
//  Granny's Recipe Keeper
//
//  Helper class for organizing ingredients into categories
//

import Foundation

class TheMealDBIngredientCategorizer {
    
    func organizeIntoCategories(_ ingredients: [TheMealDBIngredient]) -> [IngredientCategory] {
        var categories: [IngredientCategory] = []
        
        categories.append(contentsOf: createMeatPoultryCategory(from: ingredients))
        categories.append(contentsOf: createFishSeafoodCategory(from: ingredients))
        categories.append(contentsOf: createVegetablesCategory(from: ingredients))
        categories.append(contentsOf: createGrainsLegumesCategory(from: ingredients))
        categories.append(contentsOf: createDairyCategory(from: ingredients))
        categories.append(contentsOf: createSpicesHerbsCategory(from: ingredients))
        categories.append(contentsOf: createOtherCategory(from: ingredients))
        
        return categories
    }
    
    private func createMeatPoultryCategory(from ingredients: [TheMealDBIngredient]) -> [IngredientCategory] {
        let meatPoultry = ["Chicken", "Beef", "Pork", "Lamb", "Turkey", "Duck", "Bacon", "Sausage"]
        let filtered = filterAndSortIngredients(ingredients, byNames: meatPoultry)
        
        return filtered.isEmpty ? [] : [IngredientCategory(name: "Meat & Poultry", ingredients: filtered, isExpanded: true)]
    }
    
    private func createFishSeafoodCategory(from ingredients: [TheMealDBIngredient]) -> [IngredientCategory] {
        let fishSeafood = ["Salmon", "Tuna", "Cod", "Prawns", "Shrimp", "Crab", "Mussels"]
        let filtered = filterAndSortIngredients(ingredients, byNames: fishSeafood)
        
        return filtered.isEmpty ? [] : [IngredientCategory(name: "Fish & Seafood", ingredients: filtered, isExpanded: true)]
    }
    
    private func createVegetablesCategory(from ingredients: [TheMealDBIngredient]) -> [IngredientCategory] {
        let vegetables = [
            "Tomato", "Onion", "Garlic", "Potato", "Carrot", "Broccoli", "Spinach",
            "Pepper", "Bell Pepper", "Mushroom", "Courgette", "Aubergine", "Cucumber",
            "Lettuce", "Cabbage", "Cauliflower", "Celery", "Leek", "Peas"
        ]
        let filtered = filterAndSortIngredients(ingredients, byNames: vegetables)
        
        return filtered.isEmpty ? [] : [IngredientCategory(name: "Vegetables", ingredients: filtered, isExpanded: true)]
    }
    
    private func createGrainsLegumesCategory(from ingredients: [TheMealDBIngredient]) -> [IngredientCategory] {
        let grainsLegumes = ["Rice", "Pasta", "Flour", "Lentils", "Chickpeas", "Beans", "Bread"]
        let filtered = filterAndSortIngredients(ingredients, byNames: grainsLegumes)
        
        return filtered.isEmpty ? [] : [IngredientCategory(name: "Grains & Legumes", ingredients: filtered, isExpanded: true)]
    }
    
    private func createDairyCategory(from ingredients: [TheMealDBIngredient]) -> [IngredientCategory] {
        let dairyProducts = [
            "Cheese", "Butter", "Milk", "Cream", "Yogurt", "Parmesan", "Mozzarella",
            "Cheddar Cheese", "Feta", "Cream Cheese"
        ]
        let filtered = filterAndSortIngredients(ingredients, byNames: dairyProducts)
        
        return filtered.isEmpty ? [] : [IngredientCategory(name: "Dairy Products", ingredients: filtered, isExpanded: true)]
    }
    
    private func createSpicesHerbsCategory(from ingredients: [TheMealDBIngredient]) -> [IngredientCategory] {
        let spicesHerbs = [
            "Salt", "Black Pepper", "Paprika", "Cumin", "Coriander", "Basil",
            "Oregano", "Thyme", "Rosemary", "Parsley", "Mint", "Ginger", "Chili"
        ]
        let filtered = filterAndSortIngredients(ingredients, byNames: spicesHerbs)
        
        return filtered.isEmpty ? [] : [IngredientCategory(name: "Spices & Herbs", ingredients: filtered, isExpanded: true)]
    }
    
    private func createOtherCategory(from ingredients: [TheMealDBIngredient]) -> [IngredientCategory] {
        let other = [
            "Egg", "Oil", "Olive Oil", "Vinegar", "Sugar", "Honey", "Lemon",
            "Lime", "Coconut Milk", "Soy Sauce", "Tomato Paste", "Stock"
        ]
        let filtered = filterAndSortIngredients(ingredients, byNames: other)
        
        return filtered.isEmpty ? [] : [IngredientCategory(name: "Other Ingredients", ingredients: filtered, isExpanded: true)]
    }
    
    private func filterAndSortIngredients(_ ingredients: [TheMealDBIngredient], byNames names: [String]) -> [TheMealDBIngredient] {
        return ingredients
            .filter { ingredient in
                guard let name = ingredient.strIngredient else { return false }
                return names.contains(name)
            }
            .sorted { ($0.strIngredient ?? "") < ($1.strIngredient ?? "") }
    }
}

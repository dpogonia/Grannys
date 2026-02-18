//
//  TheMealDBWorker.swift
//  Granny's Recipe Keeper
//
//  Created for CleanSwift (VIP) Architecture
//

import Foundation

// ДЗ CLEANSWIFT: Worker - выполняет сетевые запросы и другую работу
// Worker инкапсулирует работу с сервисами и API

class TheMealDBWorker: TheMealDBWorkerProtocol {
    
    private let service: TheMealDBService
    private let cache: TheMealDBCache
    
    init(service: TheMealDBService = .shared, cache: TheMealDBCache = .shared) {
        self.service = service
        self.cache = cache
    }
    
    // MARK: - Categories
    func fetchCategories(completion: @escaping (Result<[TheMealDBCategory], NetworkError>) -> Void) {
        service.getCategories { result in
            completion(result)
        }
    }
    
    // MARK: - Areas (Countries)
    func fetchAreas(completion: @escaping (Result<[AreaWithFlag], NetworkError>) -> Void) {
        service.getAreas { result in
            switch result {
            case .success(let mealAreas):
                let areas = mealAreas
                    .compactMap { $0.strArea }
                    .filter { !$0.isEmpty }
                    .map { AreaWithFlag(area: $0) }
                    .sorted { $0.name < $1.name }
                completion(.success(areas))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Ingredients
    func fetchIngredients(completion: @escaping (Result<[TheMealDBIngredient], NetworkError>) -> Void) {
        service.getIngredients { result in
            switch result {
            case .success(let allIngredients):
                let popularIngredients = [
                    "Chicken", "Beef", "Pork", "Lamb", "Turkey", "Duck", "Bacon", "Sausage",
                    "Salmon", "Tuna", "Cod", "Prawns", "Shrimp", "Crab", "Mussels",
                    "Tomato", "Onion", "Garlic", "Potato", "Carrot", "Broccoli", "Spinach",
                    "Pepper", "Bell Pepper", "Mushroom", "Courgette", "Aubergine", "Cucumber",
                    "Lettuce", "Cabbage", "Cauliflower", "Celery", "Leek", "Peas",
                    "Rice", "Pasta", "Flour", "Lentils", "Chickpeas", "Beans", "Bread",
                    "Cheese", "Butter", "Milk", "Cream", "Yogurt", "Parmesan", "Mozzarella",
                    "Cheddar Cheese", "Feta", "Cream Cheese",
                    "Salt", "Black Pepper", "Paprika", "Cumin", "Coriander", "Basil",
                    "Oregano", "Thyme", "Rosemary", "Parsley", "Mint", "Ginger", "Chili",
                    "Egg", "Oil", "Olive Oil", "Vinegar", "Sugar", "Honey", "Lemon",
                    "Lime", "Coconut Milk", "Soy Sauce", "Tomato Paste", "Stock"
                ]
                
                let filtered = allIngredients.filter { ingredient in
                    guard let name = ingredient.strIngredient else { return false }
                    return popularIngredients.contains(name)
                }.sorted { ($0.strIngredient ?? "") < ($1.strIngredient ?? "") }
                
                completion(.success(filtered))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Random Recipes
    func fetchRandomRecipe(completion: @escaping (Result<TheMealDBRecipe, NetworkError>) -> Void) {
        service.getRandomRecipe(completion: completion)
    }
    
    func fetchRandomRecipes(count: Int, completion: @escaping (Result<[TheMealDBRecipe], NetworkError>) -> Void) {
        let group = DispatchGroup()
        var loadedRecipes: [TheMealDBRecipe] = []
        var lastError: NetworkError?
        
        for _ in 0..<count {
            group.enter()
            service.getRandomRecipe { result in
                switch result {
                case .success(let recipe):
                    loadedRecipes.append(recipe)
                case .failure(let error):
                    lastError = error
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if loadedRecipes.isEmpty, let error = lastError {
                completion(.failure(error))
            } else {
                completion(.success(loadedRecipes))
            }
        }
    }
    
    // MARK: - Recipes by Category
    func fetchRecipesByCategory(_ category: String, offset: Int, limit: Int, completion: @escaping (Result<[TheMealDBRecipe], NetworkError>) -> Void) {
        // Обработка объединенных категорий
        if category == "Vegan" {
            fetchMultipleCategories(["Vegan", "Vegetarian"], offset: offset, limit: limit, completion: completion)
        } else if category == "Main" {
            fetchMultipleCategories(["Miscellaneous", "Beef", "Lamb", "Pork", "Chicken", "Goat", "Lunch"], offset: offset, limit: limit, completion: completion)
        } else if category == "Side" {
            fetchMultipleCategories(["Side", "Pasta"], offset: offset, limit: limit, completion: completion)
        } else {
            service.getRecipesByCategory(category, offset: offset, limit: limit, completion: completion)
        }
    }
    
    private func fetchMultipleCategories(_ categories: [String], offset: Int, limit: Int, completion: @escaping (Result<[TheMealDBRecipe], NetworkError>) -> Void) {
        let group = DispatchGroup()
        var allRecipes: [[TheMealDBRecipe]] = Array(repeating: [], count: categories.count)
        var lastError: NetworkError?
        
        for (index, category) in categories.enumerated() {
            group.enter()
            service.getRecipesByCategory(category, offset: offset, limit: limit) { result in
                switch result {
                case .success(let recipes):
                    allRecipes[index] = recipes
                case .failure(let error):
                    if lastError == nil {
                        lastError = error
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            var combinedRecipes: [TheMealDBRecipe] = []
            for recipes in allRecipes {
                combinedRecipes.append(contentsOf: recipes)
            }
            
            // Удаляем дубликаты по idMeal
            var seenIds = Set<String>()
            combinedRecipes = combinedRecipes.filter { recipe in
                guard let id = recipe.idMeal else { return false }
                if seenIds.contains(id) {
                    return false
                }
                seenIds.insert(id)
                return true
            }
            
            if combinedRecipes.isEmpty && lastError != nil {
                completion(.failure(lastError!))
            } else {
                completion(.success(combinedRecipes))
            }
        }
    }
    
    // MARK: - Recipes by Area
    func fetchRecipesByArea(_ area: String, offset: Int, limit: Int, completion: @escaping (Result<[TheMealDBRecipe], NetworkError>) -> Void) {
        service.getRecipesByArea(area, offset: offset, limit: limit, completion: completion)
    }
    
    // MARK: - Recipes by Ingredient
    func fetchRecipesByIngredient(_ ingredient: String, offset: Int, limit: Int, completion: @escaping (Result<[TheMealDBRecipe], NetworkError>) -> Void) {
        service.getRecipesByIngredient(ingredient, offset: offset, limit: limit, completion: completion)
    }
    
    // MARK: - Recipes by Region
    func fetchRecipesByRegion(_ region: CuisineRegion, limit: Int, completion: @escaping (Result<[TheMealDBRecipe], NetworkError>) -> Void) {
        let group = DispatchGroup()
        var allRecipes: [[TheMealDBRecipe]] = []
        var lastError: NetworkError?
        
        for countryName in region.countries {
            group.enter()
            service.getRecipesByArea(countryName, offset: 0, limit: limit) { result in
                switch result {
                case .success(let recipes):
                    allRecipes.append(recipes)
                case .failure(let error):
                    if lastError == nil {
                        lastError = error
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            var combinedRecipes: [TheMealDBRecipe] = []
            for recipes in allRecipes {
                combinedRecipes.append(contentsOf: recipes)
            }
            
            // Удаляем дубликаты по idMeal
            var seenIds = Set<String>()
            combinedRecipes = combinedRecipes.filter { recipe in
                guard let id = recipe.idMeal else { return false }
                if seenIds.contains(id) {
                    return false
                }
                seenIds.insert(id)
                return true
            }
            
            // Перемешиваем для разнообразия
            combinedRecipes.shuffle()
            
            if combinedRecipes.isEmpty && lastError != nil {
                completion(.failure(lastError!))
            } else {
                completion(.success(combinedRecipes))
            }
        }
    }
    
    // MARK: - Search
    func searchRecipesByName(_ query: String, completion: @escaping (Result<[TheMealDBRecipe], NetworkError>) -> Void) {
        service.searchRecipesByName(query, completion: completion)
    }
    
    // MARK: - Cache
    func fetchCachedRecipes() -> [TheMealDBRecipe]? {
        return cache.getCachedRecipes()
    }
    
    func cacheRecipes(_ recipes: [TheMealDBRecipe]) {
        cache.cacheRecipes(recipes)
    }
}

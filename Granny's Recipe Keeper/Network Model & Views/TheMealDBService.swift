//
//  TheMealDBService.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import Foundation

class TheMealDBService {
    
    static let shared = TheMealDBService()
    
    private let baseURL = "https://www.themealdb.com/api/json/v1/1"
    
    private let networkService = NetworkService.shared
    
    private init() {}
    
    func getRandomRecipe(completion: @escaping (Result<TheMealDBRecipe, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/random.php") else {
            completion(.failure(.invalidResponse))
            return
        }
        
        networkService.get(url: url, responseType: TheMealDBRandomResponse.self) { result in
            switch result {
            case .success(let response):
                if let recipe = response.meals?.first {
                    completion(.success(recipe))
                } else {
                    completion(.failure(.noData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func searchRecipesByName(_ name: String, completion: @escaping (Result<[TheMealDBRecipe], NetworkError>) -> Void) {
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search.php?s=\(encodedName)") else {
            completion(.failure(.invalidResponse))
            return
        }
        
        networkService.get(url: url, responseType: TheMealDBSearchResponse.self) { result in
            switch result {
            case .success(let response):
                let recipes = response.meals ?? []
                completion(.success(recipes))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getRecipesByCategory(_ category: String, offset: Int = 0, limit: Int = 10, completion: @escaping (Result<[TheMealDBRecipe], NetworkError>) -> Void) {
        guard let encodedCategory = category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/filter.php?c=\(encodedCategory)") else {
            completion(.failure(.invalidResponse))
            return
        }
        
        networkService.get(url: url, responseType: TheMealDBFilterResponse.self) { [weak self] result in
            switch result {
            case .success(let filterResponse):
                let mealIds = filterResponse.meals?.compactMap { $0.idMeal } ?? []
                
                if mealIds.isEmpty {
                    completion(.success([]))
                    return
                }
                
                let endIndex = min(offset + limit, mealIds.count)
                guard offset < mealIds.count else {
                    completion(.success([]))
                    return
                }
                let paginatedIds = Array(mealIds[offset..<endIndex])
                self?.fetchRecipesDetails(ids: paginatedIds, completion: completion)
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getRecipeById(_ id: String, completion: @escaping (Result<TheMealDBRecipe, NetworkError>) -> Void) {
        guard let encodedId = id.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/lookup.php?i=\(encodedId)") else {
            completion(.failure(.invalidResponse))
            return
        }
        
        networkService.get(url: url, responseType: TheMealDBLookupResponse.self) { result in
            switch result {
            case .success(let response):
                if let recipe = response.meals?.first {
                    completion(.success(recipe))
                } else {
                    completion(.failure(.notFound(nil)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getCategories(completion: @escaping (Result<[TheMealDBCategory], NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/list.php?c=list") else {
            completion(.failure(.invalidResponse))
            return
        }
        
        networkService.get(url: url, responseType: TheMealDBCategoriesResponse.self) { result in
            switch result {
            case .success(let response):
                let categories = response.meals ?? []
                completion(.success(categories))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Получение списка областей (стран) из TheMealDB API
    func getAreas(completion: @escaping (Result<[TheMealDBArea], NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/list.php?a=list") else {
            completion(.failure(.invalidResponse))
            return
        }
        
        networkService.get(url: url, responseType: TheMealDBAreas.self) { result in
            switch result {
            case .success(let response):
                let areas = response.meals ?? []
                completion(.success(areas))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Получение рецептов по области (стране)
    func getRecipesByArea(_ area: String, offset: Int = 0, limit: Int = 10, completion: @escaping (Result<[TheMealDBRecipe], NetworkError>) -> Void) {
        guard let encodedArea = area.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/filter.php?a=\(encodedArea)") else {
            completion(.failure(.invalidResponse))
            return
        }
        
        networkService.get(url: url, responseType: TheMealDBFilterResponse.self) { [weak self] result in
            switch result {
            case .success(let filterResponse):
                let mealIds = filterResponse.meals?.compactMap { $0.idMeal } ?? []
                
                if mealIds.isEmpty {
                    completion(.success([]))
                    return
                }
                
                let endIndex = min(offset + limit, mealIds.count)
                guard offset < mealIds.count else {
                    completion(.success([]))
                    return
                }
                let paginatedIds = Array(mealIds[offset..<endIndex])
                self?.fetchRecipesDetails(ids: paginatedIds, completion: completion)
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getIngredients(completion: @escaping (Result<[TheMealDBIngredient], NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/list.php?i=list") else {
            completion(.failure(.invalidResponse))
            return
        }
        
        networkService.get(url: url, responseType: TheMealDBIngredientsResponse.self) { result in
            switch result {
            case .success(let response):
                let ingredients = response.meals ?? []
                completion(.success(ingredients))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getRecipesByIngredient(_ ingredient: String, offset: Int = 0, limit: Int = 10, completion: @escaping (Result<[TheMealDBRecipe], NetworkError>) -> Void) {
        guard let encodedIngredient = ingredient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/filter.php?i=\(encodedIngredient)") else {
            completion(.failure(.invalidResponse))
            return
        }
        
        networkService.get(url: url, responseType: TheMealDBFilterResponse.self) { [weak self] result in
            switch result {
            case .success(let filterResponse):
                let mealIds = filterResponse.meals?.compactMap { $0.idMeal } ?? []
                
                if mealIds.isEmpty {
                    completion(.success([]))
                    return
                }
                
                let endIndex = min(offset + limit, mealIds.count)
                guard offset < mealIds.count else {
                    completion(.success([]))
                    return
                }
                let paginatedIds = Array(mealIds[offset..<endIndex])
                self?.fetchRecipesDetails(ids: paginatedIds, completion: completion)
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func fetchRecipesDetails(ids: [String], completion: @escaping (Result<[TheMealDBRecipe], NetworkError>) -> Void) {
        let group = DispatchGroup()
        var recipes: [TheMealDBRecipe] = []
        var lastError: NetworkError?
        
        for id in ids {
            group.enter()
            getRecipeById(id) { result in
                switch result {
                case .success(let recipe):
                    recipes.append(recipe)
                case .failure(let error):
                    lastError = error
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if recipes.isEmpty, let error = lastError {
                completion(.failure(error))
            } else {
                completion(.success(recipes))
            }
        }
    }
    
    func convertToAPIRecipe(_ mealDBRecipe: TheMealDBRecipe) -> APIRecipe {
        var ingredients: [APIIngredient] = []
        
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
        
        for (ingredientName, measure) in ingredientPairs {
            guard let name = ingredientName,
                  !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                continue
            }
            
            var amount: Double? = nil
            var unit: String? = nil
            
            let trimmedMeasure = measure?.trimmingCharacters(in: .whitespaces) ?? ""
            if !trimmedMeasure.isEmpty {
                let components = trimmedMeasure.components(separatedBy: CharacterSet.whitespaces)
                if let firstComponent = components.first,
                   let parsedAmount = Double(firstComponent) {
                    amount = parsedAmount
                    if components.count > 1 {
                        unit = components.dropFirst().joined(separator: " ")
                    }
                } else {
                    unit = trimmedMeasure
                }
            }
            
            ingredients.append(APIIngredient(name: name, amount: amount, unit: unit))
        }
        
        var tags: [String] = []
        if let strTags = mealDBRecipe.strTags, !strTags.isEmpty {
            tags = strTags.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        
        return APIRecipe(
            id: Int(mealDBRecipe.idMeal ?? "0"),
            title: mealDBRecipe.strMeal ?? "Unknown Recipe",
            image: mealDBRecipe.strMealThumb,
            summary: mealDBRecipe.strInstructions,
            instructions: mealDBRecipe.strInstructions,
            extendedIngredients: ingredients.isEmpty ? nil : ingredients,
            tags: tags.isEmpty ? nil : tags,
            cookingTime: nil,
            servings: nil,
            difficulty: nil,
            calories: nil
        )
    }
}

struct TheMealDBRecipe: Codable {
    let idMeal: String?
    let strMeal: String?
    let strDrinkAlternate: String?
    let strCategory: String?
    let strArea: String?
    let strInstructions: String?
    let strMealThumb: String?
    let strTags: String?
    let strYoutube: String?
    let strIngredient1: String?
    let strIngredient2: String?
    let strIngredient3: String?
    let strIngredient4: String?
    let strIngredient5: String?
    let strIngredient6: String?
    let strIngredient7: String?
    let strIngredient8: String?
    let strIngredient9: String?
    let strIngredient10: String?
    let strIngredient11: String?
    let strIngredient12: String?
    let strIngredient13: String?
    let strIngredient14: String?
    let strIngredient15: String?
    let strIngredient16: String?
    let strIngredient17: String?
    let strIngredient18: String?
    let strIngredient19: String?
    let strIngredient20: String?
    let strMeasure1: String?
    let strMeasure2: String?
    let strMeasure3: String?
    let strMeasure4: String?
    let strMeasure5: String?
    let strMeasure6: String?
    let strMeasure7: String?
    let strMeasure8: String?
    let strMeasure9: String?
    let strMeasure10: String?
    let strMeasure11: String?
    let strMeasure12: String?
    let strMeasure13: String?
    let strMeasure14: String?
    let strMeasure15: String?
    let strMeasure16: String?
    let strMeasure17: String?
    let strMeasure18: String?
    let strMeasure19: String?
    let strMeasure20: String?
    let strSource: String?
    let strImageSource: String?
    let strCreativeCommonsConfirmed: String?
    let dateModified: String?
}

struct TheMealDBRandomResponse: Codable {
    let meals: [TheMealDBRecipe]?
}

struct TheMealDBSearchResponse: Codable {
    let meals: [TheMealDBRecipe]?
}

struct TheMealDBFilterResponse: Codable {
    let meals: [TheMealDBFilterItem]?
}

struct TheMealDBFilterItem: Codable {
    let strMeal: String?
    let strMealThumb: String?
    let idMeal: String?
}

struct TheMealDBLookupResponse: Codable {
    let meals: [TheMealDBRecipe]?
}

struct TheMealDBCategoriesResponse: Codable {
    let meals: [TheMealDBCategory]?
}

struct TheMealDBCategory: Codable {
    let strCategory: String?
}

// Модели для областей (стран)
struct TheMealDBAreas: Codable {
    let meals: [TheMealDBArea]?
}

struct TheMealDBArea: Codable {
    let strArea: String?
}

// Модели для ингредиентов
struct TheMealDBIngredientsResponse: Codable {
    let meals: [TheMealDBIngredient]?
}

struct TheMealDBIngredient: Codable {
    let idIngredient: String?
    let strIngredient: String?
    let strDescription: String?
    let strType: String?
}

//
//  RecipesAPIService.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

// ДЗ ТЕМА 25 CODABLE. Фото Unsplash.

import Foundation
import UIKit

// ДОМАШНЕЕ ЗАДАНИЕ ТЕМА 25 CODABLE: Использование Codable для работы с API.
// Структура для хранения данных о фотографии из Unsplash API
struct UnsplashPhoto: Codable {
    let id: String
    let urls: UnsplashPhotoURLs
    let description: String?
    let altDescription: String?
    
    // CodingKeys для маппинга между именами свойств Swift и ключами JSON
    enum CodingKeys: String, CodingKey {
        case id
        case urls
        case description
        case altDescription = "alt_description"
    }
}

// UnsplashPhotoURLs
struct UnsplashPhotoURLs: Codable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

// UnsplashSearchResponse
// Модель ответа API для поиска изображений, содержащая массив Codable структур
struct UnsplashSearchResponse: Codable {
    let results: [UnsplashPhoto]
    let total: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case results
        case total
        case totalPages = "total_pages"
    }
}

// APIRecipe
// Модель рецепта из внешнего API с опциональными свойствами для обработки отсутствующих полей в JSON
struct APIRecipe: Codable {
    let id: Int?
    let title: String
    let image: String?
    let summary: String?
    let instructions: String?
    let extendedIngredients: [APIIngredient]?
    let tags: [String]?
    let cookingTime: Int?
    let servings: Int?
    let difficulty: String?
    let calories: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case image
        case summary
        case instructions
        case extendedIngredients
        case tags
        case cookingTime
        case servings
        case difficulty
        case calories
    }
}

// Модель ингредиента из внешнего API
struct APIIngredient: Codable {
    let name: String
    let amount: Double?
    let unit: String?
    
    var displayAmount: String {
        if let amount = amount, let unit = unit, !unit.isEmpty {
            let formattedAmount = amount.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", amount) : String(format: "%.1f", amount)
            return "\(formattedAmount) \(unit)"
        } else if let amount = amount {
            let formattedAmount = amount.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", amount) : String(format: "%.1f", amount)
            return formattedAmount
        }
        return ""
    }
}

// Универсальная модель ответа API
struct APIResponse: Codable {
    let results: [APIRecipe]?
    let recipes: [APIRecipe]?
}

// RecipesAPIService
class RecipesAPIService {
    static let shared = RecipesAPIService()
    
    private init() {}
    
    // MARK: - Unsplash API
    
    private let unsplashBaseURL = "https://api.unsplash.com"
    private let unsplashAccessKey = "YOUR_UNSPLASH_ACCESS_KEY"
    
    func searchUnsplashImages(query: String, completion: @escaping (Result<[UnsplashPhoto], Error>) -> Void) {
        var components = URLComponents(string: "\(unsplashBaseURL)/search/photos")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: "20"),
            URLQueryItem(name: "orientation", value: "landscape")
        ]
        
        guard let url = components.url else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if !unsplashAccessKey.isEmpty && !unsplashAccessKey.contains("YOUR_UNSPLASH_ACCESS_KEY") {
            request.setValue("Client-ID \(unsplashAccessKey)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 {
                    let authError = NSError(
                        domain: "UnsplashAPI",
                        code: 401,
                        userInfo: [NSLocalizedDescriptionKey: "Требуется API ключ Unsplash. Получите ключ на https://unsplash.com/developers"]
                    )
                    completion(.failure(authError))
                    return
                }
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "No data", code: -1)))
                }
                return
            }
            
            Task.detached {
                do {
                    
                    // JSONDecoder для декодирования JSON в Swift объекты (Codable)
                    let searchResponse = try JSONDecoder().decode(UnsplashSearchResponse.self, from: data)
                    let photos = searchResponse.results
                    await MainActor.run {
                        completion(.success(photos))
                    }
                } catch {
                    await MainActor.run {
                        completion(.failure(error))
                    }
                }
            }
        }.resume()
    }
    
    // Загрузка изображений
    func loadImage(from urlString: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        if let cachedImage = ImageCache.shared.image(for: urlString) {
            completion(.success(cachedImage))
            return
        }
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                completion(.failure(NSError(domain: "Invalid image data", code: -1)))
                return
            }
            
            ImageCache.shared.setImage(image, for: urlString)
            
            completion(.success(image))
        }.resume()
    }
    
    // Конвертация API Recipe
    func convertToRecipe(_ apiRecipe: APIRecipe, categories: [Category] = []) -> Recipe {
        let ingredients = apiRecipe.extendedIngredients?.map { apiIngredient in
            Ingredient(name: apiIngredient.name, amount: apiIngredient.displayAmount)
        } ?? []
        
        let instructions = apiRecipe.summary ?? apiRecipe.instructions ?? ""
        
        return Recipe(
            name: apiRecipe.title,
            recipeInstructions: instructions,
            imageURL: apiRecipe.image,
            ingredients: ingredients,
            categories: categories,
            cookingTime: apiRecipe.cookingTime,
            servings: apiRecipe.servings,
            difficulty: apiRecipe.difficulty,
            calories: apiRecipe.calories,
            tags: apiRecipe.tags ?? []
        )
    }
}


import Foundation

struct RecipeExportImportService {
    
    // MARK: - DTOs
    
    struct IngredientDTO: Codable {
        let name: String
        let amount: String?
        
        init(from ingredient: Ingredient) {
            self.name = ingredient.name
            self.amount = ingredient.amount
        }
        
        func toIngredient() -> Ingredient {
            Ingredient(name: name, amount: amount)
        }
    }
    
    struct RecipeExportDTO: Codable {
        let id: UUID
        let name: String
        let instructions: String?
        let ingredients: [IngredientDTO]
        let categories: [String]
        let isArchived: Bool
        let isFavorite: Bool
        let createdAt: Date
        let cookingTime: Int?
        let servings: Int?
        let difficulty: String?
        let calories: Int?
        let tags: [String]
        let sources: [String]?
        
        init(from recipe: Recipe) {
            self.id = recipe.id
            self.name = recipe.name
            self.instructions = recipe.recipeInstructions
            self.ingredients = recipe.ingredients.map { IngredientDTO(from: $0) }
            self.categories = recipe.categories.map { $0.name }
            self.isArchived = recipe.isArchived
            self.isFavorite = recipe.isFavorite
            self.createdAt = recipe.createdAt
            self.cookingTime = recipe.cookingTime
            self.servings = recipe.servings
            self.difficulty = recipe.difficulty
            self.calories = recipe.calories
            self.tags = recipe.tags
            self.sources = recipe.sources.isEmpty ? nil : recipe.sources
        }
        
        func toRecipe() -> Recipe {
            let ingredientsModels = ingredients.map { $0.toIngredient() }
            let categoriesModels = categories.map { Category(name: $0, isDefault: false) }
            
            return Recipe(
                id: id,
                name: name,
                recipeInstructions: instructions,
                imageData: nil,
                imageURL: nil,
                ingredients: ingredientsModels,
                categories: categoriesModels,
                isArchived: isArchived,
                isFavorite: isFavorite,
                createdAt: createdAt,
                cookingTime: cookingTime,
                servings: servings,
                difficulty: difficulty,
                calories: calories,
                tags: tags,
                sources: sources ?? []
            )
        }
    }
    
    // MARK: - Export
    
    static func exportRecipesToJSON(_ recipes: [Recipe]) throws -> URL {
        let dtos = recipes.map { RecipeExportDTO(from: $0) }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(dtos)
        let url = makeTemporaryURL(extension: "json")
        try data.write(to: url, options: .atomic)
        return url
    }
    
    static func exportRecipesToCSV(_ recipes: [Recipe]) throws -> URL {
        guard !recipes.isEmpty else {
            throw NSError(domain: "RecipeExport", code: 1, userInfo: [NSLocalizedDescriptionKey: "No recipes to export"])
        }
        
        var rows: [String] = []
        let header = "name;ingredients;instructions;categories;tags;cookingTime;servings;difficulty;calories;isFavorite;isArchived;sources"
        rows.append(header)
        
        func normalize(_ value: String?) -> String {
            guard var string = value, !string.isEmpty else { return "" }
            string = string.replacingOccurrences(of: "\n", with: " ")
            string = string.replacingOccurrences(of: "\r", with: " ")
            string = string.replacingOccurrences(of: ";", with: ",")
            return string
        }
        
        for recipe in recipes {
            let ingredientsString = recipe.ingredients.map { ingredient -> String in
                let safeName = ingredient.name.replacingOccurrences(of: "|", with: "/")
                let safeAmount = (ingredient.amount ?? "").replacingOccurrences(of: "|", with: "/")
                if safeAmount.isEmpty {
                    return safeName
                } else {
                    return "\(safeName):\(safeAmount)"
                }
            }.joined(separator: "|")
            
            let categoriesString = recipe.categories
                .map { $0.name.replacingOccurrences(of: "|", with: "/") }
                .joined(separator: "|")
            
            let tagsString = recipe.tags
                .map { $0.replacingOccurrences(of: "|", with: "/") }
                .joined(separator: "|")
            
            let sourcesString = recipe.sources
                .map { $0.replacingOccurrences(of: "|", with: "/") }
                .joined(separator: "|")
            
            let fields: [String] = [
                normalize(recipe.name),
                normalize(ingredientsString),
                normalize(recipe.recipeInstructions),
                normalize(categoriesString),
                normalize(tagsString),
                recipe.cookingTime.map { String($0) } ?? "",
                recipe.servings.map { String($0) } ?? "",
                normalize(recipe.difficulty),
                recipe.calories.map { String($0) } ?? "",
                recipe.isFavorite ? "1" : "0",
                recipe.isArchived ? "1" : "0",
                normalize(sourcesString)
            ]
            
            rows.append(fields.joined(separator: ";"))
        }
        
        let csvString = rows.joined(separator: "\n")
        guard let data = csvString.data(using: .utf8) else {
            throw NSError(domain: "RecipeExport", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode CSV"])
        }
        
        let url = makeTemporaryURL(extension: "csv")
        try data.write(to: url, options: .atomic)
        return url
    }
    
    // MARK: - Import
    
    static func importRecipes(fromJSONAt url: URL) throws -> [Recipe] {
        let data = try Data(contentsOf: url)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let dtos = try decoder.decode([RecipeExportDTO].self, from: data)
            return dtos.map { $0.toRecipe() }
        } catch {
            let dto = try decoder.decode(RecipeExportDTO.self, from: data)
            return [dto.toRecipe()]
        }
    }
    
    static func importRecipes(fromCSVAt url: URL) throws -> [Recipe] {
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "RecipeImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid text encoding"])
        }
        
        let lines = content
            .components(separatedBy: CharacterSet.newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard lines.count > 1 else { return [] }
        
        let dataLines = lines.dropFirst()
        var result: [Recipe] = []
        
        for line in dataLines {
            let fields = line.components(separatedBy: ";")
            guard fields.count >= 11 else { continue }
            
            let name = fields[0]
            if name.trimmingCharacters(in: .whitespaces).isEmpty { continue }
            
            let ingredientsString = fields[1]
            let instructions = fields[2].isEmpty ? nil : fields[2]
            let categoriesString = fields[3]
            let tagsString = fields[4]
            
            let cookingTime = Int(fields[5])
            let servings = Int(fields[6])
            let difficulty = fields[7].isEmpty ? nil : fields[7]
            let calories = Int(fields[8])
            let isFavorite = fields[9] == "1"
            let isArchived = fields[10] == "1"
            let sourcesString = fields.count > 11 ? fields[11] : ""
            
            let ingredients = parseIngredients(from: ingredientsString)
            let categories = parseCategories(from: categoriesString)
            let tags = parseTags(from: tagsString)
            let sources = parseSources(from: sourcesString)
            
            let recipe = Recipe(
                name: name,
                recipeInstructions: instructions,
                imageData: nil,
                imageURL: nil,
                ingredients: ingredients,
                categories: categories,
                isArchived: isArchived,
                isFavorite: isFavorite,
                createdAt: Date(),
                cookingTime: cookingTime,
                servings: servings,
                difficulty: difficulty,
                calories: calories,
                tags: tags,
                sources: sources
            )
            
            result.append(recipe)
        }
        
        return result
    }
    
    // MARK: - Helpers
    
    private static func makeTemporaryURL(extension ext: String) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let dateString = formatter.string(from: Date())
        let fileName = "recipes-\(dateString).\(ext)"
        return FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    }
    
    private static func parseIngredients(from value: String) -> [Ingredient] {
        guard !value.isEmpty else { return [] }
        
        return value
            .components(separatedBy: "|")
            .compactMap { part -> Ingredient? in
                let trimmed = part.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return nil }
                
                let components = trimmed.components(separatedBy: ":")
                let name = components.first ?? ""
                let amount = components.count > 1 ? components[1] : nil
                
                return Ingredient(name: name, amount: amount)
            }
    }
    
    private static func parseCategories(from value: String) -> [Category] {
        guard !value.isEmpty else { return [] }
        
        return value
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { Category(name: $0, isDefault: false) }
    }
    
    private static func parseTags(from value: String) -> [String] {
        guard !value.isEmpty else { return [] }
        
        return value
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    private static func parseSources(from value: String) -> [String] {
        guard !value.isEmpty else { return [] }
        
        return value
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}


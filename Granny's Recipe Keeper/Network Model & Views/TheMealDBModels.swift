
import Foundation

// Load Categories
enum LoadCategories {
    struct Request { }
    
    struct Response {
        let categories: [TheMealDBCategory]
        let error: NetworkError?
    }
    
    struct ViewModel {
        struct DisplayedCategory {
            let name: String
            let isSelected: Bool
        }
        
        let categories: [DisplayedCategory]
        let errorMessage: String?
    }
}

// Load Countries
enum LoadCountries {
    struct Request {
        // Пустой запрос - не требует параметров
    }
    
    struct Response {
        let areas: [AreaWithFlag]
        let error: NetworkError?
    }
    
    struct ViewModel {
        struct DisplayedCountry {
            let name: String
            let flagEmoji: String
            let isSelected: Bool
        }
        
        let countries: [DisplayedCountry]
        let errorMessage: String?
    }
}

// Load Ingredients
enum LoadIngredients {
    struct Request {
        // Пустой запрос - не требует параметров
    }
    
    struct Response {
        let ingredients: [TheMealDBIngredient]
        let error: NetworkError?
    }
    
    struct ViewModel {
        struct DisplayedIngredient {
            let name: String
            let thumbnailURL: String?
            let isSelected: Bool
        }
        
        let ingredients: [DisplayedIngredient]
        let errorMessage: String?
    }
}

// Load Recipes
enum LoadRecipes {
    struct Request {
        enum FilterType {
            case random
            case category(String)
            case area(AreaWithFlag)
            case ingredient(TheMealDBIngredient)
            case search(String)
            case region(CuisineRegion)
            case ingredientWithArea(ingredient: TheMealDBIngredient, area: String)
            case ingredientWithRegion(ingredient: TheMealDBIngredient, region: CuisineRegion)
        }
        
        let filterType: FilterType
        let append: Bool
        let offset: Int
        let limit: Int
    }
    
    struct Response {
        let recipes: [TheMealDBRecipe]
        let hasMore: Bool
        let error: NetworkError?
    }
    
    struct ViewModel {
        struct DisplayedRecipe {
            let id: String
            let name: String
            let imageURL: String?
            let category: String?
            let area: String?
        }
        
        let recipes: [DisplayedRecipe]
        let shouldAppend: Bool
        let hasMore: Bool
        let title: String
        let errorMessage: String?
    }
}

// Select Category
enum SelectCategory {
    struct Request {
        let categoryIndex: Int
    }
    
    struct Response {
        let selectedCategory: String?
    }
    
    struct ViewModel {
        let selectedCategory: String?
    }
}

// Apply Filters
enum ApplyFilters {
    struct Request {
        let selectedArea: AreaWithFlag?
        let selectedRegion: CuisineRegion?
        let selectedIngredient: TheMealDBIngredient?
    }
    
    struct Response {
        // Response обрабатывается через LoadRecipes
    }
    
    struct ViewModel {
        // ViewModel обрабатывается через LoadRecipes
    }
}

// Search Recipes
enum SearchRecipes {
    struct Request {
        let query: String
    }
    
    struct Response {
        // Response обрабатывается через LoadRecipes
    }
    
    struct ViewModel {
        // ViewModel обрабатывается через LoadRecipes
    }
}

// Load Random Recipe
enum LoadRandomRecipe {
    struct Request {
        // Пустой запрос - не требует параметров
    }
    
    struct Response {
        let recipe: TheMealDBRecipe?
        let error: NetworkError?
    }
    
    struct ViewModel {
        let recipe: LoadRecipes.ViewModel.DisplayedRecipe?
        let errorMessage: String?
    }
}

// Show Recipe Detail
enum ShowRecipeDetail {
    struct Request {
        let recipeIndex: Int
    }
    
    struct Response {
        let recipe: TheMealDBRecipe
    }
    
    struct ViewModel {
        // Навигация обрабатывается через Router
    }
}



import Foundation

enum RecipesModels {
    
    // MARK: - Initial Load
    
    enum InitialLoad {
        struct Request { }
    }
    
    // MARK: - Refresh
    
    enum Refresh {
        struct Request { }
    }
    
    // MARK: - Search
    
    enum Search {
        struct Request {
            let query: String
        }
    }
    
    // MARK: - Category Selection
    
    enum CategorySelection {
        struct Request {
            let category: Category?
        }
    }
    
    // MARK: - Filters
    
    enum Filters {
        struct Request {
            let selectedTags: Set<String>
            let selectedDifficulty: String?
            let selectedIngredients: Set<String>
        }
    }
    
    // MARK: - List
    
    enum List {
        struct Response {
            let recipes: [Recipe]
            let selectedCategory: Category?
            let isSearching: Bool
        }
        
        struct ViewModel {
            let recipes: [Recipe]
        }
    }
    
    // MARK: - Empty State
    
    enum EmptyState {
        struct Response {
            let isEmpty: Bool
        }
        
        struct ViewModel {
            let isEmpty: Bool
        }
    }
    
    // MARK: - Error
    
    enum Error {
        struct Response {
            let message: String
        }
        
        struct ViewModel {
            let message: String
        }
    }
    
    // MARK: - Selection
    
    enum Selection {
        struct Request {
            let index: Int
        }
        
        struct Response {
            let recipe: Recipe
        }
        
        struct ViewModel {
            let recipe: Recipe
        }
    }
    
    // MARK: - Delete
    
    enum Delete {
        struct Request {
            let recipe: Recipe
        }
    }
}


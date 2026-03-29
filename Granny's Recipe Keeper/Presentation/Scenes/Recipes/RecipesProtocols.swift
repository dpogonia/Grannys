

import Foundation

// MARK: - View (ViewController)

/// Отвечает за отображение данных и обработку готовых view models.
protocol RecipesDisplayLogic: AnyObject {
    func displayRecipes(_ viewModel: RecipesModels.List.ViewModel)
    func displayEmptyState(_ viewModel: RecipesModels.EmptyState.ViewModel)
    func displayError(_ viewModel: RecipesModels.Error.ViewModel)
}

// MARK: - Interactor (Business Logic)

/// Содержит бизнес‑логику списка рецептов.
protocol RecipesBusinessLogic {
    func loadInitialData(_ request: RecipesModels.InitialLoad.Request)
    func refresh(_ request: RecipesModels.Refresh.Request)
    func updateSearch(_ request: RecipesModels.Search.Request)
    func selectCategory(_ request: RecipesModels.CategorySelection.Request)
    func applyFilters(_ request: RecipesModels.Filters.Request)
    func selectRecipe(_ request: RecipesModels.Selection.Request)
    func deleteRecipe(_ request: RecipesModels.Delete.Request)
}

// MARK: - Presenter (Presentation Logic)

/// Форматирует доменные модели в view models для отображения.
protocol RecipesPresentationLogic {
    func presentRecipes(_ response: RecipesModels.List.Response)
    func presentEmptyState(_ response: RecipesModels.EmptyState.Response)
    func presentError(_ response: RecipesModels.Error.Response)
    func presentSelection(_ response: RecipesModels.Selection.Response)
}

// MARK: - Router (Navigation)

/// Отвечает за навигацию между сценами.
protocol RecipesRoutingLogic {
    func routeToCategories()
    func routeToRecipeEdit()
    func routeToFilter()
    func routeToMealDB()
    func routeToRecipeDetail()
}

/// Передача данных между сценами.
protocol RecipesDataPassing {
    var dataStore: RecipesDataStore? { get }
}

// MARK: - Data Store

/// Хранилище состояния сцены `Recipes`.
protocol RecipesDataStore: AnyObject {
    var recipes: [Recipe] { get set }
    var allCategories: [Category] { get set }
    var selectedCategory: Category? { get set }
    var isSearching: Bool { get set }
    var filterTags: Set<String> { get set }
    var filterDifficulty: String? { get set }
    var filterIngredients: Set<String> { get set }
}

// MARK: - Worker

/// Обёртка над репозиторием/сервисами для Interactor-а.
protocol RecipesWorkerProtocol {
    func fetchAllCategories() -> [Category]
    func fetchRecipes(in category: Category?, archived: Bool) -> [Recipe]
    func fetchFavoriteRecipes() -> [Recipe]
    func fetchArchivedRecipes() -> [Recipe]
    func searchRecipes(query: String, in category: Category?) -> [Recipe]
    func archiveRecipe(_ recipe: Recipe)
    func unarchiveRecipe(_ recipe: Recipe)
    func deleteRecipe(_ recipe: Recipe)
    func toggleFavorite(_ recipe: Recipe) -> Recipe?
}


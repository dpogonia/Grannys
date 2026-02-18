//
//  TheMealDBProtocols.swift
//  Granny's Recipe Keeper
//
//  Created for CleanSwift (VIP) Architecture
//  Protocols (Interfaces) separated from implementations
//

import Foundation

// MARK: - Business Logic Protocol (Interactor Interface)

protocol TheMealDBBusinessLogic {
    func loadCategories(request: LoadCategories.Request)
    func loadCountries(request: LoadCountries.Request)
    func loadIngredients(request: LoadIngredients.Request)
    func loadRecipes(request: LoadRecipes.Request)
    func selectCategory(request: SelectCategory.Request)
    func applyFilters(request: ApplyFilters.Request)
    func searchRecipes(request: SearchRecipes.Request)
    func loadRandomRecipe(request: LoadRandomRecipe.Request)
    func showRecipeDetail(request: ShowRecipeDetail.Request)
    func loadCachedRecipes()
}

// MARK: - Data Store Protocol

protocol TheMealDBDataStore {
    var recipes: [TheMealDBRecipe] { get set }
    var categories: [TheMealDBCategory] { get set }
    var areas: [AreaWithFlag] { get set }
    var ingredients: [TheMealDBIngredient] { get set }
    var selectedCategory: String? { get set }
    var selectedArea: AreaWithFlag? { get set }
    var selectedIngredient: TheMealDBIngredient? { get set }
    var currentOffset: Int { get set }
    var hasMoreRecipes: Bool { get set }
    var lastFilterType: LoadRecipes.Request.FilterType? { get set }
}

// MARK: - Presentation Logic Protocol (Presenter Interface)

protocol TheMealDBPresentationLogic {
    func presentCategories(response: LoadCategories.Response)
    func presentCountries(response: LoadCountries.Response)
    func presentIngredients(response: LoadIngredients.Response)
    func presentRecipes(response: LoadRecipes.Response, append: Bool, selectedCategory: String?, selectedArea: AreaWithFlag?, selectedIngredient: TheMealDBIngredient?)
    func presentSelectedCategory(response: SelectCategory.Response)
    func presentRandomRecipe(response: LoadRandomRecipe.Response)
    func presentRecipeDetail(response: ShowRecipeDetail.Response)
}

// MARK: - Display Logic Protocol (ViewController Interface)

protocol TheMealDBDisplayLogic: AnyObject {
    func displayCategories(viewModel: LoadCategories.ViewModel)
    func displayCountries(viewModel: LoadCountries.ViewModel)
    func displayIngredients(viewModel: LoadIngredients.ViewModel)
    func displayRecipes(viewModel: LoadRecipes.ViewModel)
    func displaySelectedCategory(viewModel: SelectCategory.ViewModel)
    func displayRandomRecipe(viewModel: LoadRandomRecipe.ViewModel)
    func displayRecipeDetail(viewModel: ShowRecipeDetail.ViewModel)
}

// MARK: - Routing Protocol

protocol TheMealDBRoutingLogic {
    func routeToRecipeDetail(recipe: TheMealDBRecipe)
    func routeToFilters(areas: [AreaWithFlag], ingredients: [TheMealDBIngredient], selectedArea: AreaWithFlag?, selectedIngredient: TheMealDBIngredient?)
    func routeToSearch()
    func routeBack()
}

// MARK: - Data Passing Protocol

protocol TheMealDBDataPassing {
    var dataStore: TheMealDBDataStore? { get }
}

// MARK: - Worker Protocol

protocol TheMealDBWorkerProtocol {
    func fetchCategories(completion: @escaping (Result<[TheMealDBCategory], NetworkError>) -> Void)
    func fetchAreas(completion: @escaping (Result<[AreaWithFlag], NetworkError>) -> Void)
    func fetchIngredients(completion: @escaping (Result<[TheMealDBIngredient], NetworkError>) -> Void)
    func fetchRandomRecipe(completion: @escaping (Result<TheMealDBRecipe, NetworkError>) -> Void)
    func fetchRandomRecipes(count: Int, completion: @escaping (Result<[TheMealDBRecipe], NetworkError>) -> Void)
    func fetchRecipesByCategory(_ category: String, offset: Int, limit: Int, completion: @escaping (Result<[TheMealDBRecipe], NetworkError>) -> Void)
    func fetchRecipesByArea(_ area: String, offset: Int, limit: Int, completion: @escaping (Result<[TheMealDBRecipe], NetworkError>) -> Void)
    func fetchRecipesByIngredient(_ ingredient: String, offset: Int, limit: Int, completion: @escaping (Result<[TheMealDBRecipe], NetworkError>) -> Void)
    func fetchRecipesByRegion(_ region: CuisineRegion, limit: Int, completion: @escaping (Result<[TheMealDBRecipe], NetworkError>) -> Void)
    func searchRecipesByName(_ query: String, completion: @escaping (Result<[TheMealDBRecipe], NetworkError>) -> Void)
    func fetchCachedRecipes() -> [TheMealDBRecipe]?
    func cacheRecipes(_ recipes: [TheMealDBRecipe])
}

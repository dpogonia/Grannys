//
//  TheMealDBInteractor.swift
//  Granny's Recipe Keeper
//
//  Created for CleanSwift (VIP) Architecture
//

import Foundation

// ДЗ CLEANSWIFT: Interactor - бизнес-логика приложения
// Interactor получает запросы от ViewController, обрабатывает их через Worker,
// и отправляет результаты в Presenter

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
}

class TheMealDBInteractor: TheMealDBBusinessLogic, TheMealDBDataStore {
    
    var presenter: TheMealDBPresentationLogic?
    var worker: TheMealDBWorkerProtocol
    
    // MARK: - Data Store
    var recipes: [TheMealDBRecipe] = []
    var categories: [TheMealDBCategory] = []
    var areas: [AreaWithFlag] = []
    var ingredients: [TheMealDBIngredient] = []
    var selectedCategory: String? = nil
    var selectedArea: AreaWithFlag? = nil
    var selectedIngredient: TheMealDBIngredient? = nil
    var currentOffset: Int = 0
    var hasMoreRecipes: Bool = true
    
    private let pageSize = 10
    
    init(worker: TheMealDBWorkerProtocol = TheMealDBWorker()) {
        self.worker = worker
    }
    
    // MARK: - Business Logic
    
    func loadCategories(request: LoadCategories.Request) {
        worker.fetchCategories { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedCategories):
                // Фильтруем и объединяем категории
                let allowedCategories: Set<String> = [
                    "Breakfast", "Dessert", "Miscellaneous", "Side", "Starter",
                    "Vegan", "Vegetarian", "Beverage", "Seafood", "Lunch", "Salad",
                    "Beef", "Lamb", "Pork", "Chicken", "Goat", "Pasta"
                ]
                
                var filteredCategories = fetchedCategories.filter { category in
                    guard let categoryName = category.strCategory else { return false }
                    return allowedCategories.contains(categoryName)
                }
                
                // Объединяем Vegetarian в Vegan
                if filteredCategories.contains(where: { $0.strCategory == "Vegetarian" }) {
                    filteredCategories.removeAll { $0.strCategory == "Vegetarian" }
                    if !filteredCategories.contains(where: { $0.strCategory == "Vegan" }) {
                        filteredCategories.append(TheMealDBCategory(strCategory: "Vegan"))
                    }
                }
                
                // Объединяем мясные категории и Lunch в Main
                let mainCategories = ["Beef", "Lamb", "Pork", "Chicken", "Goat", "Lunch"]
                let hasMainCategories = filteredCategories.contains { category in
                    guard let name = category.strCategory else { return false }
                    return mainCategories.contains(name)
                }
                
                if hasMainCategories {
                    filteredCategories.removeAll { category in
                        guard let name = category.strCategory else { return false }
                        return mainCategories.contains(name)
                    }
                    if !filteredCategories.contains(where: { $0.strCategory == "Main" }) {
                        filteredCategories.append(TheMealDBCategory(strCategory: "Main"))
                    }
                }
                
                // Объединяем Pasta в Side
                if filteredCategories.contains(where: { $0.strCategory == "Pasta" }) {
                    filteredCategories.removeAll { $0.strCategory == "Pasta" }
                    if !filteredCategories.contains(where: { $0.strCategory == "Side" }) {
                        filteredCategories.append(TheMealDBCategory(strCategory: "Side"))
                    }
                }
                
                // Сортируем в нужном порядке
                let customOrder = ["Starter", "Salad", "Breakfast", "Main", "Seafood", "Side", "Beverage", "Dessert", "Vegan", "Miscellaneous"]
                filteredCategories.sort { cat1, cat2 in
                    let name1 = cat1.strCategory ?? ""
                    let name2 = cat2.strCategory ?? ""
                    let index1 = customOrder.firstIndex(of: name1) ?? Int.max
                    let index2 = customOrder.firstIndex(of: name2) ?? Int.max
                    return index1 < index2
                }
                
                self.categories = filteredCategories
                let response = LoadCategories.Response(categories: filteredCategories, error: nil)
                self.presenter?.presentCategories(response: response)
                
            case .failure(let error):
                let response = LoadCategories.Response(categories: [], error: error)
                self.presenter?.presentCategories(response: response)
            }
        }
    }
    
    func loadCountries(request: LoadCountries.Request) {
        worker.fetchAreas { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedAreas):
                self.areas = fetchedAreas
                let response = LoadCountries.Response(areas: fetchedAreas, error: nil)
                self.presenter?.presentCountries(response: response)
                
            case .failure(let error):
                let response = LoadCountries.Response(areas: [], error: error)
                self.presenter?.presentCountries(response: response)
            }
        }
    }
    
    func loadIngredients(request: LoadIngredients.Request) {
        worker.fetchIngredients { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedIngredients):
                self.ingredients = fetchedIngredients
                let response = LoadIngredients.Response(ingredients: fetchedIngredients, error: nil)
                self.presenter?.presentIngredients(response: response)
                
            case .failure(let error):
                let response = LoadIngredients.Response(ingredients: [], error: error)
                self.presenter?.presentIngredients(response: response)
            }
        }
    }
    
    func loadRecipes(request: LoadRecipes.Request) {
        if !request.append {
            currentOffset = 0
            hasMoreRecipes = true
        }
        
        switch request.filterType {
        case .random:
            loadRandomRecipes(request: request)
            
        case .category(let category):
            loadRecipesByCategory(category: category, request: request)
            
        case .area(let area):
            loadRecipesByArea(area: area, request: request)
            
        case .ingredient(let ingredient):
            loadRecipesByIngredient(ingredient: ingredient, request: request)
            
        case .search(let query):
            searchRecipes(query: query, request: request)
            
        case .region(let region):
            loadRecipesByRegion(region: region, request: request)
            
        case .ingredientWithArea(let ingredient, let area):
            loadRecipesWithIngredientAndArea(ingredient: ingredient, area: area, request: request)
            
        case .ingredientWithRegion(let ingredient, let region):
            loadRecipesWithIngredientAndRegion(ingredient: ingredient, region: region, request: request)
        }
    }
    
    private func loadRandomRecipes(request: LoadRecipes.Request) {
        let count = request.append ? 5 : 10
        
        worker.fetchRandomRecipes(count: count) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedRecipes):
                if request.append {
                    self.recipes.append(contentsOf: fetchedRecipes)
                } else {
                    self.recipes = fetchedRecipes
                    self.selectedCategory = nil
                    self.worker.cacheRecipes(fetchedRecipes)
                }
                
                let response = LoadRecipes.Response(
                    recipes: fetchedRecipes,
                    hasMore: true,
                    error: nil
                )
                self.presenter?.presentRecipes(response: response, append: request.append, selectedCategory: self.selectedCategory, selectedArea: self.selectedArea, selectedIngredient: self.selectedIngredient)
                
            case .failure(let error):
                if !request.append {
                    self.hasMoreRecipes = false
                }
                let response = LoadRecipes.Response(recipes: [], hasMore: false, error: error)
                self.presenter?.presentRecipes(response: response, append: request.append, selectedCategory: self.selectedCategory, selectedArea: self.selectedArea, selectedIngredient: self.selectedIngredient)
            }
        }
    }
    
    private func loadRecipesByCategory(category: String, request: LoadRecipes.Request) {
        worker.fetchRecipesByCategory(category, offset: request.offset, limit: request.limit) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedRecipes):
                if request.append {
                    self.recipes.append(contentsOf: fetchedRecipes)
                    self.currentOffset += fetchedRecipes.count
                } else {
                    self.recipes = fetchedRecipes
                    self.selectedCategory = category
                    self.currentOffset = fetchedRecipes.count
                    self.worker.cacheRecipes(fetchedRecipes)
                }
                
                let hasMore = fetchedRecipes.count >= request.limit
                self.hasMoreRecipes = hasMore
                
                let response = LoadRecipes.Response(
                    recipes: fetchedRecipes,
                    hasMore: hasMore,
                    error: nil
                )
                self.presenter?.presentRecipes(response: response, append: request.append, selectedCategory: self.selectedCategory, selectedArea: self.selectedArea, selectedIngredient: self.selectedIngredient)
                
            case .failure(let error):
                self.hasMoreRecipes = false
                let response = LoadRecipes.Response(recipes: [], hasMore: false, error: error)
                self.presenter?.presentRecipes(response: response, append: request.append, selectedCategory: self.selectedCategory, selectedArea: self.selectedArea, selectedIngredient: self.selectedIngredient)
            }
        }
    }
    
    private func loadRecipesByArea(area: AreaWithFlag, request: LoadRecipes.Request) {
        worker.fetchRecipesByArea(area.name, offset: request.offset, limit: request.limit) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedRecipes):
                if request.append {
                    self.recipes.append(contentsOf: fetchedRecipes)
                    self.currentOffset += fetchedRecipes.count
                } else {
                    self.recipes = fetchedRecipes
                    self.currentOffset = fetchedRecipes.count
                    self.worker.cacheRecipes(fetchedRecipes)
                }
                
                let hasMore = fetchedRecipes.count >= request.limit
                self.hasMoreRecipes = hasMore
                
                let response = LoadRecipes.Response(
                    recipes: fetchedRecipes,
                    hasMore: hasMore,
                    error: nil
                )
                self.presenter?.presentRecipes(response: response, append: request.append, selectedCategory: self.selectedCategory, selectedArea: self.selectedArea, selectedIngredient: self.selectedIngredient)
                
            case .failure(let error):
                self.hasMoreRecipes = false
                let response = LoadRecipes.Response(recipes: [], hasMore: false, error: error)
                self.presenter?.presentRecipes(response: response, append: request.append, selectedCategory: self.selectedCategory, selectedArea: self.selectedArea, selectedIngredient: self.selectedIngredient)
            }
        }
    }
    
    private func loadRecipesByIngredient(ingredient: TheMealDBIngredient, request: LoadRecipes.Request) {
        guard let ingredientName = ingredient.strIngredient else { return }
        
        worker.fetchRecipesByIngredient(ingredientName, offset: request.offset, limit: request.limit) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedRecipes):
                if request.append {
                    self.recipes.append(contentsOf: fetchedRecipes)
                    self.currentOffset += fetchedRecipes.count
                } else {
                    self.recipes = fetchedRecipes
                    self.currentOffset = fetchedRecipes.count
                    self.worker.cacheRecipes(fetchedRecipes)
                }
                
                let hasMore = fetchedRecipes.count >= request.limit
                self.hasMoreRecipes = hasMore
                
                let response = LoadRecipes.Response(
                    recipes: fetchedRecipes,
                    hasMore: hasMore,
                    error: nil
                )
                self.presenter?.presentRecipes(response: response, append: request.append, selectedCategory: self.selectedCategory, selectedArea: self.selectedArea, selectedIngredient: self.selectedIngredient)
                
            case .failure(let error):
                self.hasMoreRecipes = false
                let response = LoadRecipes.Response(recipes: [], hasMore: false, error: error)
                self.presenter?.presentRecipes(response: response, append: request.append, selectedCategory: self.selectedCategory, selectedArea: self.selectedArea, selectedIngredient: self.selectedIngredient)
            }
        }
    }
    
    private func searchRecipes(query: String, request: LoadRecipes.Request) {
        hasMoreRecipes = false
        
        worker.searchRecipesByName(query) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedRecipes):
                self.recipes = fetchedRecipes
                self.selectedCategory = nil
                self.worker.cacheRecipes(fetchedRecipes)
                
                let response = LoadRecipes.Response(
                    recipes: fetchedRecipes,
                    hasMore: false,
                    error: nil
                )
                self.presenter?.presentRecipes(response: response, append: false, selectedCategory: self.selectedCategory, selectedArea: self.selectedArea, selectedIngredient: self.selectedIngredient)
                
            case .failure(let error):
                let response = LoadRecipes.Response(recipes: [], hasMore: false, error: error)
                self.presenter?.presentRecipes(response: response, append: false, selectedCategory: self.selectedCategory, selectedArea: self.selectedArea, selectedIngredient: self.selectedIngredient)
            }
        }
    }
    
    private func loadRecipesByRegion(region: CuisineRegion, request: LoadRecipes.Request) {
        worker.fetchRecipesByRegion(region, limit: request.limit) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedRecipes):
                self.recipes = fetchedRecipes
                self.currentOffset = fetchedRecipes.count
                self.worker.cacheRecipes(fetchedRecipes)
                self.hasMoreRecipes = false // Для регионов пагинация не поддерживается
                
                let response = LoadRecipes.Response(
                    recipes: fetchedRecipes,
                    hasMore: false,
                    error: nil
                )
                self.presenter?.presentRecipes(response: response, append: false, selectedCategory: self.selectedCategory, selectedArea: self.selectedArea, selectedIngredient: self.selectedIngredient)
                
            case .failure(let error):
                self.hasMoreRecipes = false
                let response = LoadRecipes.Response(recipes: [], hasMore: false, error: error)
                self.presenter?.presentRecipes(response: response, append: false, selectedCategory: self.selectedCategory, selectedArea: self.selectedArea, selectedIngredient: self.selectedIngredient)
            }
        }
    }
    
    private func loadRecipesWithIngredientAndArea(ingredient: TheMealDBIngredient, area: String, request: LoadRecipes.Request) {
        guard let ingredientName = ingredient.strIngredient else { return }
        hasMoreRecipes = false
        
        worker.fetchRecipesByIngredient(ingredientName, offset: 0, limit: 1000) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedRecipes):
                let filteredRecipes = fetchedRecipes.filter { recipe in
                    recipe.strArea?.lowercased() == area.lowercased()
                }
                
                self.recipes = filteredRecipes
                self.currentOffset = filteredRecipes.count
                self.worker.cacheRecipes(filteredRecipes)
                
                let response = LoadRecipes.Response(
                    recipes: filteredRecipes,
                    hasMore: false,
                    error: nil
                )
                self.presenter?.presentRecipes(response: response, append: false, selectedCategory: self.selectedCategory, selectedArea: self.selectedArea, selectedIngredient: self.selectedIngredient)
                
            case .failure(let error):
                let response = LoadRecipes.Response(recipes: [], hasMore: false, error: error)
                self.presenter?.presentRecipes(response: response, append: false, selectedCategory: self.selectedCategory, selectedArea: self.selectedArea, selectedIngredient: self.selectedIngredient)
            }
        }
    }
    
    private func loadRecipesWithIngredientAndRegion(ingredient: TheMealDBIngredient, region: CuisineRegion, request: LoadRecipes.Request) {
        guard let ingredientName = ingredient.strIngredient else { return }
        hasMoreRecipes = false
        
        worker.fetchRecipesByIngredient(ingredientName, offset: 0, limit: 1000) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let fetchedRecipes):
                let filteredRecipes = fetchedRecipes.filter { recipe in
                    guard let area = recipe.strArea else { return false }
                    return region.countries.contains(area)
                }
                
                self.recipes = filteredRecipes
                self.currentOffset = filteredRecipes.count
                self.worker.cacheRecipes(filteredRecipes)
                
                let response = LoadRecipes.Response(
                    recipes: filteredRecipes,
                    hasMore: false,
                    error: nil
                )
                self.presenter?.presentRecipes(response: response, append: false, selectedCategory: self.selectedCategory, selectedArea: self.selectedArea, selectedIngredient: self.selectedIngredient)
                
            case .failure(let error):
                let response = LoadRecipes.Response(recipes: [], hasMore: false, error: error)
                self.presenter?.presentRecipes(response: response, append: false, selectedCategory: self.selectedCategory, selectedArea: self.selectedArea, selectedIngredient: self.selectedIngredient)
            }
        }
    }
    
    func selectCategory(request: SelectCategory.Request) {
        if request.categoryIndex == 0 {
            // "All Recipes" выбран
            selectedCategory = nil
            selectedArea = nil
            selectedIngredient = nil
            
            let loadRequest = LoadRecipes.Request(
                filterType: .random,
                append: false,
                offset: 0,
                limit: pageSize
            )
            loadRecipes(request: loadRequest)
        } else {
            let category = categories[request.categoryIndex - 1]
            if let categoryName = category.strCategory {
                selectedCategory = categoryName
                selectedArea = nil
                selectedIngredient = nil
                
                let loadRequest = LoadRecipes.Request(
                    filterType: .category(categoryName),
                    append: false,
                    offset: 0,
                    limit: pageSize
                )
                loadRecipes(request: loadRequest)
            }
        }
        
        let response = SelectCategory.Response(selectedCategory: selectedCategory)
        presenter?.presentSelectedCategory(response: response)
    }
    
    func applyFilters(request: ApplyFilters.Request) {
        selectedArea = request.selectedArea
        selectedIngredient = request.selectedIngredient
        
        currentOffset = 0
        hasMoreRecipes = true
        
        let loadRequest: LoadRecipes.Request
        
        // Определяем тип фильтра
        if let ingredient = request.selectedIngredient {
            selectedCategory = nil
            
            if let cuisineRegion = request.selectedRegion {
                selectedArea = nil
                loadRequest = LoadRecipes.Request(
                    filterType: .ingredientWithRegion(ingredient: ingredient, region: cuisineRegion),
                    append: false,
                    offset: 0,
                    limit: pageSize
                )
            } else if let area = request.selectedArea {
                loadRequest = LoadRecipes.Request(
                    filterType: .ingredientWithArea(ingredient: ingredient, area: area.name),
                    append: false,
                    offset: 0,
                    limit: pageSize
                )
            } else {
                selectedArea = nil
                loadRequest = LoadRecipes.Request(
                    filterType: .ingredient(ingredient),
                    append: false,
                    offset: 0,
                    limit: pageSize
                )
            }
        } else if let cuisineRegion = request.selectedRegion {
            selectedCategory = nil
            selectedArea = nil
            selectedIngredient = nil
            loadRequest = LoadRecipes.Request(
                filterType: .region(cuisineRegion),
                append: false,
                offset: 0,
                limit: pageSize
            )
        } else if let area = request.selectedArea {
            selectedCategory = nil
            selectedIngredient = nil
            loadRequest = LoadRecipes.Request(
                filterType: .area(area),
                append: false,
                offset: 0,
                limit: pageSize
            )
        } else if let category = selectedCategory {
            selectedArea = nil
            selectedIngredient = nil
            loadRequest = LoadRecipes.Request(
                filterType: .category(category),
                append: false,
                offset: 0,
                limit: pageSize
            )
        } else {
            loadRequest = LoadRecipes.Request(
                filterType: .random,
                append: false,
                offset: 0,
                limit: pageSize
            )
        }
        
        loadRecipes(request: loadRequest)
    }
    
    func searchRecipes(request: SearchRecipes.Request) {
        let loadRequest = LoadRecipes.Request(
            filterType: .search(request.query),
            append: false,
            offset: 0,
            limit: pageSize
        )
        loadRecipes(request: loadRequest)
    }
    
    func loadRandomRecipe(request: LoadRandomRecipe.Request) {
        worker.fetchRandomRecipe { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let recipe):
                self.recipes = [recipe]
                self.selectedCategory = nil
                let response = LoadRandomRecipe.Response(recipe: recipe, error: nil)
                self.presenter?.presentRandomRecipe(response: response)
                
            case .failure(let error):
                let response = LoadRandomRecipe.Response(recipe: nil, error: error)
                self.presenter?.presentRandomRecipe(response: response)
            }
        }
    }
    
    func showRecipeDetail(request: ShowRecipeDetail.Request) {
        guard request.recipeIndex < recipes.count else { return }
        let recipe = recipes[request.recipeIndex]
        let response = ShowRecipeDetail.Response(recipe: recipe)
        presenter?.presentRecipeDetail(response: response)
    }
    
    func loadCachedRecipes() {
        if let cachedRecipes = worker.fetchCachedRecipes() {
            recipes = cachedRecipes
            let response = LoadRecipes.Response(recipes: cachedRecipes, hasMore: true, error: nil)
            presenter?.presentRecipes(response: response, append: false, selectedCategory: selectedCategory, selectedArea: selectedArea, selectedIngredient: selectedIngredient)
        }
    }
}

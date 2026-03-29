

import Foundation

// Presenter получает Response от Interactor и преобразует в ViewModel для ViewController

class TheMealDBPresenter: TheMealDBPresentationLogic {
    
    weak var viewController: TheMealDBDisplayLogic?
    
    // MARK: - Presentation Logic
    
    func presentCategories(response: LoadCategories.Response) {
        var displayedCategories: [LoadCategories.ViewModel.DisplayedCategory] = []
        
        for category in response.categories {
            let rawName = category.strCategory ?? "Unknown"
            let displayName = CategoryLocalization.localizedMealDBCategoryName(rawName)
            let displayedCategory = LoadCategories.ViewModel.DisplayedCategory(
                name: displayName,
                isSelected: false
            )
            displayedCategories.append(displayedCategory)
        }
        
        let viewModel = LoadCategories.ViewModel(
            categories: displayedCategories,
            errorMessage: response.error?.localizedDescription
        )
        
        viewController?.displayCategories(viewModel: viewModel)
    }
    
    func presentCountries(response: LoadCountries.Response) {
        var displayedCountries: [LoadCountries.ViewModel.DisplayedCountry] = []
        
        for area in response.areas {
            let displayedCountry = LoadCountries.ViewModel.DisplayedCountry(
                name: area.name,
                flagEmoji: area.flagEmoji,
                isSelected: false
            )
            displayedCountries.append(displayedCountry)
        }
        
        let viewModel = LoadCountries.ViewModel(
            countries: displayedCountries,
            errorMessage: response.error?.localizedDescription
        )
        
        viewController?.displayCountries(viewModel: viewModel)
    }
    
    func presentIngredients(response: LoadIngredients.Response) {
        var displayedIngredients: [LoadIngredients.ViewModel.DisplayedIngredient] = []
        
        for ingredient in response.ingredients {
            // TheMealDB API предоставляет изображения ингредиентов по URL шаблону
            let thumbnailURL: String? = {
                if let name = ingredient.strIngredient {
                    return "https://www.themealdb.com/images/ingredients/\(name).png"
                }
                return nil
            }()
            
            let displayedIngredient = LoadIngredients.ViewModel.DisplayedIngredient(
                name: ingredient.strIngredient ?? "Unknown",
                thumbnailURL: thumbnailURL,
                isSelected: false
            )
            displayedIngredients.append(displayedIngredient)
        }
        
        let viewModel = LoadIngredients.ViewModel(
            ingredients: displayedIngredients,
            errorMessage: response.error?.localizedDescription
        )
        
        viewController?.displayIngredients(viewModel: viewModel)
    }
    
    func presentRecipes(response: LoadRecipes.Response, append: Bool, selectedCategory: String?, selectedArea: AreaWithFlag?, selectedIngredient: TheMealDBIngredient?) {
        var displayedRecipes: [LoadRecipes.ViewModel.DisplayedRecipe] = []
        
        for recipe in response.recipes {
            let displayedRecipe = LoadRecipes.ViewModel.DisplayedRecipe(
                id: recipe.idMeal ?? UUID().uuidString,
                name: recipe.strMeal ?? "Unknown Recipe",
                imageURL: recipe.strMealThumb,
                category: recipe.strCategory,
                area: recipe.strArea
            )
            displayedRecipes.append(displayedRecipe)
        }
        
        let title = formatTitle(selectedCategory: selectedCategory, selectedArea: selectedArea, selectedIngredient: selectedIngredient)
        
        let viewModel = LoadRecipes.ViewModel(
            recipes: displayedRecipes,
            shouldAppend: append,
            hasMore: response.hasMore,
            title: title,
            errorMessage: response.error?.localizedDescription
        )
        
        viewController?.displayRecipes(viewModel: viewModel)
    }
    
    func presentSelectedCategory(response: SelectCategory.Response) {
        let viewModel = SelectCategory.ViewModel(
            selectedCategory: response.selectedCategory
        )
        viewController?.displaySelectedCategory(viewModel: viewModel)
    }
    
    func presentRandomRecipe(response: LoadRandomRecipe.Response) {
        var displayedRecipe: LoadRecipes.ViewModel.DisplayedRecipe?
        
        if let recipe = response.recipe {
            displayedRecipe = LoadRecipes.ViewModel.DisplayedRecipe(
                id: recipe.idMeal ?? UUID().uuidString,
                name: recipe.strMeal ?? "Unknown Recipe",
                imageURL: recipe.strMealThumb,
                category: recipe.strCategory,
                area: recipe.strArea
            )
        }
        
        let viewModel = LoadRandomRecipe.ViewModel(
            recipe: displayedRecipe,
            errorMessage: response.error?.localizedDescription
        )
        
        viewController?.displayRandomRecipe(viewModel: viewModel)
    }
    
    func presentRecipeDetail(response: ShowRecipeDetail.Response) {
        // Вызываем Router напрямую для навигации (через ViewController)
        let viewModel = ShowRecipeDetail.ViewModel()
        viewController?.displayRecipeDetail(viewModel: viewModel)
    }
    
    // MARK: - Helpers
    
    private func formatTitle(selectedCategory: String?, selectedArea: AreaWithFlag?, selectedIngredient: TheMealDBIngredient?) -> String {
        if let ingredient = selectedIngredient, let name = ingredient.strIngredient {
            return "TheMealDB - 🥘 \(name)"
        } else if let area = selectedArea {
            return "TheMealDB - \(area.flagEmoji) \(area.name)"
        } else if let category = selectedCategory {
            return "TheMealDB - \(category)"
        } else {
            return "TheMealDB Recipes"
        }
    }
}

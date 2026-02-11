//
//  TheMealDBRouter.swift
//  Granny's Recipe Keeper
//
//  Created for CleanSwift (VIP) Architecture
//

import UIKit

// ДЗ CLEANSWIFT: Router - управляет навигацией
// Router отвечает за переходы между экранами и передачу данных

protocol TheMealDBRoutingLogic {
    func routeToRecipeDetail(recipe: TheMealDBRecipe)
    func routeToFilters(areas: [AreaWithFlag], ingredients: [TheMealDBIngredient], selectedArea: AreaWithFlag?, selectedIngredient: TheMealDBIngredient?)
    func routeToSearch()
    func routeBack()
}

protocol TheMealDBDataPassing {
    var dataStore: TheMealDBDataStore? { get }
}

class TheMealDBRouter: NSObject, TheMealDBRoutingLogic, TheMealDBDataPassing {
    
    weak var viewController: TheMealDBViewController?
    var dataStore: TheMealDBDataStore?
    
    func routeToRecipeDetail(recipe: TheMealDBRecipe) {
        let apiRecipe = TheMealDBService.shared.convertToAPIRecipe(recipe)
        let convertedRecipe = RecipesAPIService.shared.convertToRecipe(apiRecipe)
        
        if #available(iOS 13.0, *) {
            let previewVC = RecipePreviewViewController(recipe: convertedRecipe, apiRecipe: apiRecipe)
            previewVC.delegate = viewController
            viewController?.navigationController?.pushViewController(previewVC, animated: true)
        } else {
            let categoriesVC = CategoriesSelectionViewController()
            categoriesVC.delegate = viewController
            categoriesVC.apiRecipe = apiRecipe
            viewController?.navigationController?.pushViewController(categoriesVC, animated: true)
        }
    }
    
    func routeToFilters(areas: [AreaWithFlag], ingredients: [TheMealDBIngredient], selectedArea: AreaWithFlag?, selectedIngredient: TheMealDBIngredient?) {
        let filterVC = TheMealDBFilterViewController(
            areas: areas,
            ingredients: ingredients,
            selectedArea: selectedArea,
            selectedIngredient: selectedIngredient
        )
        filterVC.delegate = viewController
        
        let navController = UINavigationController(rootViewController: filterVC)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        viewController?.present(navController, animated: true)
    }
    
    func routeToSearch() {
        let alert = UIAlertController(title: "Search Recipe", message: "Enter recipe name", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Recipe name"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Search", style: .default) { [weak self] _ in
            guard let query = alert.textFields?.first?.text, !query.isEmpty else { return }
            let request = SearchRecipes.Request(query: query)
            self?.viewController?.interactor?.searchRecipes(request: request)
        })
        
        viewController?.present(alert, animated: true)
    }
    
    func routeBack() {
        viewController?.dismiss(animated: true)
    }
}

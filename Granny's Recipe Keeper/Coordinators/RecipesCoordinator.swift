//
//  RecipeCommand.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 28.03.2026.
//

import UIKit

protocol RecipesCoordinating: AnyObject {
    func showCategories(selectedCategory: Category?)
    func showCreateRecipe()
    func showFilters(selectedTags: Set<String>, selectedDifficulty: String?)
    func showMealDB()
    func showRecipeDetail(recipe: Recipe)
}

final class RecipesCoordinator: Coordinator {
    let navigationController: UINavigationController
    
    private weak var recipesViewController: RecipesViewController?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let recipesVC = RecipesViewController()
        recipesVC.coordinator = self
        recipesViewController = recipesVC
        
        navigationController.setViewControllers([recipesVC], animated: false)
    }
}

extension RecipesCoordinator: RecipesCoordinating {
    func showCategories(selectedCategory: Category?) {
        guard let recipesVC = recipesViewController else { return }
        let categoriesVC = CategoriesViewController()
        categoriesVC.delegate = recipesVC
        categoriesVC.selectedCategory = selectedCategory
        navigationController.pushViewController(categoriesVC, animated: true)
    }
    
    func showCreateRecipe() {
        guard let recipesVC = recipesViewController else { return }
        let editVC = RecipeEditViewController()
        editVC.delegate = recipesVC
        navigationController.pushViewController(editVC, animated: true)
    }
    
    func showFilters(selectedTags: Set<String>, selectedDifficulty: String?) {
        guard let recipesVC = recipesViewController else { return }
        let filterVC = FilterViewController(selectedTags: selectedTags, selectedDifficulty: selectedDifficulty)
        filterVC.delegate = recipesVC
        let navController = UINavigationController(rootViewController: filterVC)
        recipesVC.present(navController, animated: true)
    }
    
    func showMealDB() {
        let mealDBVC = TheMealDBViewController()
        let navController = UINavigationController(rootViewController: mealDBVC)
        navController.modalPresentationStyle = .fullScreen
        navigationController.present(navController, animated: true)
    }
    
    func showRecipeDetail(recipe: Recipe) {
        guard let recipesVC = recipesViewController else { return }
        let detailVC = RecipeDetailViewController(recipe: recipe)
        detailVC.delegate = recipesVC
        navigationController.pushViewController(detailVC, animated: true)
    }
}


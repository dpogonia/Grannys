//
//  RecipeCommand.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 28.03.2026.
//

import UIKit

final class AppCoordinator: Coordinator {
    let window: UIWindow
    let navigationController: UINavigationController
    
    private var recipesCoordinator: RecipesCoordinator?
    
    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
    }
    
    func start() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        let recipesCoordinator = RecipesCoordinator(navigationController: navigationController)
        self.recipesCoordinator = recipesCoordinator
        recipesCoordinator.start()
    }
}


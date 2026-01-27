//
//  AppDelegate.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        _ = CoreDataManager.shared
        
        addMockDataIfNeeded()
        
        return true
    }
    
    private func addMockDataIfNeeded() {
        
        let recipes = RecipesRepository.shared.getAllRecipes()
        
        if recipes.isEmpty {
            
            let mockRecipes = RecipesRepository.mockRecipes()
            
            for recipe in mockRecipes {
                RecipesRepository.shared.saveRecipe(recipe)
            }
        }
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}

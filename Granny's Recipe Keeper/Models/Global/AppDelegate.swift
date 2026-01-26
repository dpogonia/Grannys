//
//  AppDelegate.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit
import CoreData

// MARK: - AppDelegate
// AppDelegate - это главный "менеджер" приложения, который управляет жизненным циклом всего приложения

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    // Эта функция вызывается, когда приложение только запускается
    // Это как "включение" приложения - здесь мы настраиваем всё необходимое перед показом экрана пользователю
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Инициализируем Core Data - база данных для хранения рецептов и другой информации
        
        // CoreDataManager.shared - это паттерн Singleton, то есть во всём приложении будет только ОДИН экземпляр CoreDataManager. Представь его как единственный склад, куда все ходят за данными.
        _ = CoreDataManager.shared
        
        // Если база данных пустая, добавляем несколько примеров рецептов, чтобы пользователю было что посмотреть
        addMockDataIfNeeded()
        
        // Возвращаем true, чтобы сказать системе: "Всё готово, можно показывать приложение!"
        return true
    }
    
    // Функция проверяет, есть ли рецепты в базе данных, и если нет - добавляет тестовые
    private func addMockDataIfNeeded() {
        
        // Получаем все рецепты из базы данных
        let recipes = RecipesRepository.shared.getAllRecipes()
        
        // Если рецептов нет (массив пустой), добавляем тестовые данные
        if recipes.isEmpty {
            
            // Получаем список тестовых рецептов (это статический метод, вызывается через имя класса)
            let mockRecipes = RecipesRepository.mockRecipes()
            
            // Проходим по каждому тестовому рецепту и сохраняем его в базу данных
            for recipe in mockRecipes {
                RecipesRepository.shared.saveRecipe(recipe)
            }
        }
    }
    
    // MARK: UISceneSession Lifecycle
    
    // Эта функция настраивает сцены (окна) приложения
    // В iOS 13+ приложение может иметь несколько окон (например, на iPad)
    // Эта функция говорит системе, как создавать новые окна
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Возвращаем стандартную конфигурацию сцены
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    // Эта функция вызывается, когда система удаляет сцену (окно)
    // Например, когда пользователь закрывает приложение
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Здесь можно освободить ресурсы, связанные с удалёнными сценами
        // В нашем случае ничего делать не нужно
    }
}

//
//  SceneDelegate.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

// MARK: - SceneDelegate
// SceneDelegate управляет жизненным циклом конкретного окна (сцены) приложения
// Если AppDelegate - это дирижёр всего оркестра, то SceneDelegate - дирижёр одного конкретного концерта
// В iOS 13+ приложение может иметь несколько окон, и каждое окно имеет свой SceneDelegate
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // window - это окно приложения, в котором отображается интерфейс
    // Это как рамка картины: внутри неё мы показываем пользователю наш интерфейс
    var window: UIWindow?

    // Эта функция вызывается, когда система создаёт новое окно приложения
    // Здесь мы настраиваем, какой экран показывать пользователю первым
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // guard - это "охранник": если условие не выполнится, функция прекратит работу (return)
        // Здесь мы проверяем, что scene действительно является UIWindowScene
        // as? - это безопасное приведение типа: если не получится, вернётся nil
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Создаём новое окно, связанное с этой сценой
        let window = UIWindow(windowScene: windowScene)
        
        // Создаём главный экран приложения - список рецептов
        let recipesViewController = RecipesViewController()
        
        // UINavigationController - это контейнер, который позволяет переходить между экранами
        // Представь его как книгу: recipesViewController - это первая страница
        // Когда пользователь нажимает на рецепт, мы "переворачиваем страницу" и показываем детали
        let navigationController = UINavigationController(rootViewController: recipesViewController)
        
        // Устанавливаем navigationController как корневой (главный) контроллер окна
        // Это как сказать: "Показывай этот экран первым, когда откроется окно"
        window.rootViewController = navigationController
        
        // Сохраняем ссылку на окно в свойство класса
        self.window = window
        
        // Делаем окно видимым и активным
        // Без этого окно будет создано, но не будет показано пользователю
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}

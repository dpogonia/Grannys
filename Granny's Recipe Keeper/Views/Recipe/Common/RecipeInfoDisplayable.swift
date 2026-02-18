//
//  RecipeInfoDisplayable.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 28.01.2026.
//

import UIKit

// MARK: - RecipeInfoDisplayable
// Протокол для отображения информации о рецепте
protocol RecipeInfoDisplayable: AnyObject {
    var recipeInfoLabel: UILabel { get }
    func configureRecipeInfo(for recipe: Recipe)
}

extension RecipeInfoDisplayable {

    func configureRecipeInfo(for recipe: Recipe) {
        var infoParts: [String] = []

        if let cookingTime = recipe.cookingTime, cookingTime > 0 {
            infoParts.append("⏱ \(cookingTime) min")
        }

        if let servings = recipe.servings, servings > 0 {
            infoParts.append("👥 \(servings) servings")
        }

        if let calories = recipe.calories, calories > 0 {
            infoParts.append("🔥 \(calories) cal")
        }

        if let difficulty = recipe.difficulty, !difficulty.isEmpty {
            let stars = difficultyStars(for: difficulty)
            let capitalizedDifficulty = difficulty.prefix(1).uppercased() + difficulty.dropFirst()
            infoParts.append("\(stars) \(capitalizedDifficulty)")
        }

        if infoParts.isEmpty {
            recipeInfoLabel.isHidden = true
        } else {
            // Убираем точки между элементами и делаем строку адаптивной
            recipeInfoLabel.text = infoParts.joined(separator: "   ")
            recipeInfoLabel.adjustsFontSizeToFitWidth = true
            recipeInfoLabel.minimumScaleFactor = 0.7
            recipeInfoLabel.numberOfLines = 1
            recipeInfoLabel.isHidden = false
        }
    }

    private func difficultyStars(for difficulty: String) -> String {
        switch difficulty.lowercased() {
        case "easy":
            return "⭐"
        case "medium":
            return "⭐⭐"
        case "hard":
            return "⭐⭐⭐"
        default:
            return "⭐"
        }
    }
}

// MARK: - RecipeImageLoadable
// Протокол для загрузки изображений рецепта
protocol RecipeImageLoadable: AnyObject {
    func loadRecipeImage(_ recipe: Recipe, into imageView: UIImageView)
}

extension RecipeImageLoadable {

    func loadRecipeImage(_ recipe: Recipe, into imageView: UIImageView) {
        if let image = recipe.image {
            imageView.image = image
            imageView.backgroundColor = .clear
        } else if let imageURL = recipe.imageURL, !imageURL.isEmpty {
            RecipesAPIService.shared.loadImage(from: imageURL) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let image):
                        imageView.image = image
                        imageView.backgroundColor = .clear
                    case .failure:
                        imageView.image = UIImage(named: "default")
                        imageView.backgroundColor = .secondarySystemBackground
                    }
                }
            }
        } else {
            imageView.image = UIImage(named: "default")
            imageView.backgroundColor = .secondarySystemBackground
        }
    }
}

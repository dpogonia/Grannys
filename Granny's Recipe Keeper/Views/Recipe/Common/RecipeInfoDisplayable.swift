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
        var infoParts: [NSAttributedString] = []

        let accentColor: UIColor = recipeInfoLabel.tintColor ?? .grannyPink
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .regular)

        func makeSymbolAttachment(_ systemName: String) -> NSAttributedString {
            guard let baseImage = UIImage(systemName: systemName, withConfiguration: symbolConfig) else {
                return NSAttributedString(string: "")
            }
            let image = baseImage.withTintColor(accentColor, renderingMode: .alwaysOriginal)
            let attachment = NSTextAttachment()
            attachment.image = image
            // Немного приподнимаем иконку относительно базовой линии текста
            attachment.bounds = CGRect(x: 0, y: -2, width: image.size.width, height: image.size.height)
            return NSAttributedString(attachment: attachment)
        }

        if let cookingTime = recipe.cookingTime, cookingTime > 0 {
            let part = NSMutableAttributedString()
            part.append(makeSymbolAttachment("timer"))
            part.append(NSAttributedString(string: " \(cookingTime) min"))
            infoParts.append(part)
        }

        if let servings = recipe.servings, servings > 0 {
            let part = NSMutableAttributedString()
            part.append(makeSymbolAttachment("person.2"))
            part.append(NSAttributedString(string: " \(servings) servings"))
            infoParts.append(part)
        }

        if let calories = recipe.calories, calories > 0 {
            let part = NSMutableAttributedString()
            part.append(makeSymbolAttachment("flame"))
            part.append(NSAttributedString(string: " \(calories) cal"))
            infoParts.append(part)
        }

        if let difficulty = recipe.difficulty, !difficulty.isEmpty {
            let capitalizedDifficulty = difficulty.prefix(1).uppercased() + difficulty.dropFirst()
            let part = NSMutableAttributedString()
            part.append(makeSymbolAttachment("star.fill"))
            part.append(NSAttributedString(string: " \(capitalizedDifficulty)"))
            infoParts.append(part)
        }

        if infoParts.isEmpty {
            recipeInfoLabel.isHidden = true
        } else {
            // Собираем итоговую строку с отступами между блоками
            let result = NSMutableAttributedString()
            for (index, part) in infoParts.enumerated() {
                if index > 0 {
                    result.append(NSAttributedString(string: "   "))
                }
                result.append(part)
            }

            recipeInfoLabel.attributedText = result
            recipeInfoLabel.adjustsFontSizeToFitWidth = true
            recipeInfoLabel.minimumScaleFactor = 0.7
            recipeInfoLabel.numberOfLines = 1
            recipeInfoLabel.isHidden = false
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

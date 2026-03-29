//
//  RecipeCommand.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 28.01.2026.
//

import Foundation

protocol RecipeCommand {
    func execute()
    func undo()
    var description: String { get }
}

class DeleteRecipeCommand: RecipeCommand {
    private let recipe: Recipe
    private var wasDeleted = false

    var description: String {
        return "Recipe deleted"
    }

    init(recipe: Recipe) {
        self.recipe = recipe
    }

    func execute() {
        RecipesRepository.shared.archiveRecipe(recipe)
        wasDeleted = true
        print("✅ Command: Recipe archived - \(recipe.name)")
    }

    func undo() {
        guard wasDeleted else { return }

        // Восстанавливаем рецепт из архива
        var restoredRecipe = recipe
        restoredRecipe.isArchived = false
        RecipesRepository.shared.saveRecipe(restoredRecipe)
        wasDeleted = false
        print("↩️ Command: Recipe restored - \(recipe.name)")
    }
}

// MARK: - ToggleFavoriteCommand
// Команда переключения избранного с возможностью отмены
class ToggleFavoriteCommand: RecipeCommand {
    private let recipe: Recipe
    private var previousState: Bool

    var description: String {
        return previousState ? "Removed from favorites" : "Added to favorites"
    }

    init(recipe: Recipe) {
        self.recipe = recipe
        self.previousState = recipe.isFavorite
    }

    func execute() {
        RecipesRepository.shared.toggleFavorite(recipe)
        print("✅ Command: Favorite toggled - \(recipe.name)")
    }

    func undo() {
        // Восстанавливаем предыдущее состояние
        if let currentRecipe = RecipesRepository.shared.getRecipe(by: recipe.id) {
            var updatedRecipe = currentRecipe
            updatedRecipe.isFavorite = previousState
            RecipesRepository.shared.saveRecipe(updatedRecipe)
            print("↩️ Command: Favorite state restored - \(recipe.name)")
        }
    }
}

// MARK: - ArchiveRecipeCommand
// Команда архивации / разархивации рецепта с возможностью Undo
class ArchiveRecipeCommand: RecipeCommand {
    private let recipe: Recipe
    private let previousIsArchived: Bool

    var description: String {
        return previousIsArchived ? "Recipe restored from archive" : "Recipe moved to archive"
    }

    init(recipe: Recipe) {
        self.recipe = recipe
        self.previousIsArchived = recipe.isArchived
    }

    func execute() {
        if previousIsArchived {
            RecipesRepository.shared.unarchiveRecipe(recipe)
            print("✅ Command: Recipe unarchived - \(recipe.name)")
        } else {
            RecipesRepository.shared.archiveRecipe(recipe)
            print("✅ Command: Recipe archived - \(recipe.name)")
        }
    }

    func undo() {
        if let currentRecipe = RecipesRepository.shared.getRecipe(by: recipe.id) {
            var updated = currentRecipe
            updated.isArchived = previousIsArchived
            RecipesRepository.shared.saveRecipe(updated)
            print("↩️ Command: Archive state restored - \(recipe.name)")
        }
    }
}

// MARK: - CommandManager
// Менеджер команд с историей для поддержки Undo
class CommandManager {
    static let shared = CommandManager()

    private var commandHistory: [RecipeCommand] = []
    private let maxHistorySize = 10

    private init() {}

    // Выполнить команду и добавить в историю
    func execute(command: RecipeCommand) {
        command.execute()
        commandHistory.append(command)

        // Ограничиваем размер истории
        if commandHistory.count > maxHistorySize {
            commandHistory.removeFirst()
        }
    }

    // Отменить последнюю команду
    func undo() -> RecipeCommand? {
        guard let lastCommand = commandHistory.popLast() else {
            print("ℹ️ No commands to undo")
            return nil
        }

        lastCommand.undo()
        return lastCommand
    }

    // Проверить наличие команд для отмены
    func canUndo() -> Bool {
        return !commandHistory.isEmpty
    }

    // Очистить историю
    func clearHistory() {
        commandHistory.removeAll()
        print("🗑️ Command history cleared")
    }
}

//
//  FilterMemento.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 28.01.2026.
//

import Foundation

struct FilterMemento: Codable {
    let selectedTags: [String]
    let selectedDifficulty: String?
    let selectedIngredients: [String]
    let savedAt: Date

    init(selectedTags: Set<String>, selectedDifficulty: String?, selectedIngredients: Set<String>) {
        self.selectedTags = Array(selectedTags)
        self.selectedDifficulty = selectedDifficulty
        self.selectedIngredients = Array(selectedIngredients)
        self.savedAt = Date()
    }

    var tagsSet: Set<String> {
        return Set(selectedTags)
    }

    var ingredientsSet: Set<String> {
        return Set(selectedIngredients)
    }
}

class FilterCaretaker {
    static let shared = FilterCaretaker()

    private let userDefaults = UserDefaults.standard
    private let filterMementoKey = "FilterMementoKey"

    private init() {}

    // Сохранить состояние фильтров
    func saveFilterState(memento: FilterMemento) {
        if let encoded = try? JSONEncoder().encode(memento) {
            userDefaults.set(encoded, forKey: filterMementoKey)
            userDefaults.synchronize()
            print("✅ Filters saved: tags=\(memento.selectedTags.count), difficulty=\(memento.selectedDifficulty ?? "nil"), ingredients=\(memento.selectedIngredients.count)")
        }
    }

    // Восстановить состояние фильтров
    func restoreFilterState() -> FilterMemento? {
        guard let data = userDefaults.data(forKey: filterMementoKey),
              let memento = try? JSONDecoder().decode(FilterMemento.self, from: data) else {
            print("ℹ️ No saved filters found")
            return nil
        }
        print("✅ Filters restored: tags=\(memento.selectedTags.count), difficulty=\(memento.selectedDifficulty ?? "nil"), ingredients=\(memento.selectedIngredients.count)")
        return memento
    }

    // Очистить сохраненное состояние
    func clearFilterState() {
        userDefaults.removeObject(forKey: filterMementoKey)
        userDefaults.synchronize()
        print("🗑️ Filters cleared")
    }

    // Проверить наличие сохраненных фильтров
    func hasSavedFilters() -> Bool {
        return userDefaults.data(forKey: filterMementoKey) != nil
    }
}

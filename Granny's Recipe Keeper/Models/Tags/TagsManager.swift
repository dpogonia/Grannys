//
//  TagsManager.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import Foundation

// MARK: - TagsManager
// TagsManager - это менеджер для управления глобальными тегами приложения
// Теги хранятся глобально, чтобы они были доступны во всех рецептах
// АНАЛОГИЯ: Как общий словарь тегов для всего приложения - если добавил тег в одном рецепте,
// он появится и в других рецептах
class TagsManager {
    // Singleton паттерн - один экземпляр на всё приложение
    static let shared = TagsManager()
    
    // Ключ для сохранения тегов в UserDefaults
    private let customTagsKey = "CustomTags"
    private let deletedTagsKey = "DeletedTags"
    
    // Стандартные теги (нельзя удалить, всегда доступны)
    let defaultTags = [
        "Vegetarian",
        "Vegan",
        "Gluten-Free",
        "Lactose-Free",
        "Low-Calorie",
        "Quick",
        "Kid-Friendly",
        "Spicy",
        "Sweet",
        "Healthy",
        "Sugar-Free",
        "Nut-Free"
    ]
    
    // Приватный инициализатор (часть паттерна Singleton)
    private init() {}
    
    // MARK: - Custom Tags (Пользовательские теги)
    
    // Получить все пользовательские теги
    // UserDefaults - это хранилище настроек приложения (сохраняется между запусками)
    // АНАЛОГИЯ: Как файл настройки - данные сохраняются и остаются после перезапуска приложения
    func getCustomTags() -> [String] {
        // UserDefaults.standard.array - получает массив из хранилища
        // forKey: customTagsKey - ключ, по которому ищем данные (как имя файла)
        // as? [String] - безопасное приведение типа к массиву строк
        // Если данные не являются массивом строк, вернётся nil
        // ?? [] - nil coalescing operator: если nil, возвращаем пустой массив
        // АНАЛОГИЯ: "Если файл не найден, используй пустой список"
        return UserDefaults.standard.array(forKey: customTagsKey) as? [String] ?? []
    }
    
    // Добавить новый пользовательский тег
    // ИСПРАВЛЕНИЕ БАГА: Тег теперь добавляется глобально и будет доступен во всех рецептах
    // Если добавил тег в Рецепте1, он появится и в Рецепте2
    func addCustomTag(_ tag: String) {
        // Проверяем, что тег не пустой и не содержит только пробелы
        // trimmingCharacters - убирает пробелы в начале и конце строки
        let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        // guard - "охранник": если условие не выполнится, функция прекратит работу
        guard !trimmedTag.isEmpty else { return }
        
        // Получаем текущие пользовательские теги из хранилища
        var customTags = getCustomTags()
        
        // Проверяем, нет ли уже такого тега (чтобы избежать дубликатов)
        if !customTags.contains(trimmedTag) {
            // Добавляем новый тег в конец массива
            customTags.append(trimmedTag)
            // Сортируем по алфавиту для удобства (чтобы теги были в порядке A-Z)
            customTags.sort()
            // Сохраняем обновлённый список в UserDefaults
            // set(_:forKey:) - сохраняет данные в хранилище
            UserDefaults.standard.set(customTags, forKey: customTagsKey)
        }
    }
    
    // Удалить пользовательский тег глобально
    // ИСПРАВЛЕНИЕ БАГА: Удаление из одного рецепта теперь удалит тег везде
    // Если удалил тег у Рецепта1, он удалится и у Рецепта2, и из общего списка
    func deleteCustomTag(_ tag: String) {
        // Получаем текущие пользовательские теги
        var customTags = getCustomTags()
        // removeAll - удаляет все элементы, которые соответствуют условию
        // { $0 == tag } - замыкание: удалить элемент, если он равен tag
        // $0 - это каждый элемент массива
        customTags.removeAll { $0 == tag }
        // Сохраняем обновлённый список (без удалённого тега)
        UserDefaults.standard.set(customTags, forKey: customTagsKey)
        
        // Добавляем в список удалённых (чтобы не показывать в будущем)
        // Это нужно, чтобы тег не появился снова при следующем запуске
        var deletedTags = getDeletedTags()
        deletedTags.insert(tag) // insert - добавляет элемент в Set
        // Сохраняем список удалённых тегов
        // Set нужно преобразовать в Array для сохранения в UserDefaults
        UserDefaults.standard.set(Array(deletedTags), forKey: deletedTagsKey)
    }
    
    // Изменить название тега
    // ИСПРАВЛЕНИЕ: Добавлена возможность редактирования тегов
    // Старое название заменяется на новое во всех рецептах автоматически
    func renameTag(oldName: String, newName: String) {
        // Убираем пробелы в начале и конце нового названия
        let trimmedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        // Проверяем, что новое название не пустое
        guard !trimmedNewName.isEmpty else { return }
        
        // Если это пользовательский тег, обновляем его в списке пользовательских тегов
        var customTags = getCustomTags()
        // firstIndex - находит индекс первого элемента, который равен oldName
        if let index = customTags.firstIndex(of: oldName) {
            // Заменяем старое название на новое
            customTags[index] = trimmedNewName
            // Сортируем по алфавиту
            customTags.sort()
            // Сохраняем обновлённый список
            UserDefaults.standard.set(customTags, forKey: customTagsKey)
        }
        
        // ВАЖНО: Обновляем тег во всех рецептах
        // Получаем все рецепты из базы данных
        let allRecipes = RecipesRepository.shared.getAllRecipes(archived: false)
        // Проходим по каждому рецепту
        for recipe in allRecipes {
            // Проверяем, содержит ли рецепт старый тег
            if recipe.tags.contains(oldName) {
                // Создаём копию массива тегов рецепта
                var updatedTags = recipe.tags
                // Находим индекс старого тега
                if let tagIndex = updatedTags.firstIndex(of: oldName) {
                    // Заменяем старый тег на новый
                    updatedTags[tagIndex] = trimmedNewName
                    // Создаём копию рецепта с обновлёнными тегами
                    var updatedRecipe = recipe
                    updatedRecipe.tags = updatedTags
                    // Сохраняем обновлённый рецепт в базу данных
                    RecipesRepository.shared.saveRecipe(updatedRecipe)
                }
            }
        }
    }
    
    // MARK: - Deleted Tags (Удалённые теги)
    
    // Получить список удалённых тегов
    // Set<String> - это коллекция уникальных строк (без дубликатов)
    // Используется Set, потому что нам не важна последовательность, только наличие тега
    func getDeletedTags() -> Set<String> {
        // Получаем массив из UserDefaults
        let array = UserDefaults.standard.array(forKey: deletedTagsKey) as? [String] ?? []
        // Преобразуем массив в Set (множество)
        return Set(array)
    }
    
    // Получить все доступные теги (стандартные + пользовательские, исключая удалённые)
    // Этот метод используется для отображения списка тегов в интерфейсе
    func getAllAvailableTags() -> [String] {
        // Получаем пользовательские теги из хранилища
        let customTags = getCustomTags()
        // Получаем список удалённых тегов
        let deletedTags = getDeletedTags()
        
        // Объединяем стандартные и пользовательские теги
        // + - оператор конкатенации массивов (соединения)
        let allTags = defaultTags + customTags
        
        // Фильтруем удалённые теги
        // filter - оставляет только те элементы, которые соответствуют условию
        // { !deletedTags.contains($0) } - оставить тег, если его НЕТ в deletedTags
        // $0 - это каждый элемент массива allTags
        return allTags.filter { !deletedTags.contains($0) }
    }
    
    // Получить все теги из всех рецептов (для фильтров)
    // Используется в FilterViewController для показа всех возможных тегов для фильтрации
    func getAllTagsFromRecipes() -> [String] {
        // Получаем все неархивированные рецепты
        let allRecipes = RecipesRepository.shared.getAllRecipes(archived: false)
        // Set - коллекция уникальных элементов (без дубликатов)
        var tagsSet: Set<String> = []
        
        // Собираем все теги из всех рецептов
        // Двойной цикл: для каждого рецепта проходим по всем его тегам
        for recipe in allRecipes {
            for tag in recipe.tags {
                // insert - добавляет элемент в Set (если уже есть, не добавит дубликат)
                tagsSet.insert(tag)
            }
        }
        
        // Добавляем стандартные и пользовательские теги (чтобы они были доступны для фильтрации)
        let availableTags = getAllAvailableTags()
        for tag in availableTags {
            tagsSet.insert(tag)
        }
        
        // Возвращаем отсортированный массив
        // Array(tagsSet) - преобразуем Set в массив
        // .sorted() - сортируем по алфавиту
        return Array(tagsSet).sorted()
    }
}

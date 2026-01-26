//
//  CategoriesViewController.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

// MARK: - CategoriesViewControllerDelegate
// Протокол для уведомления о выборе категории
// Delegate паттерн позволяет одному объекту сообщить другому о событиях
protocol CategoriesViewControllerDelegate: AnyObject {
    func didSelectCategory(_ category: Category?) // Категория была выбрана (nil = "Все рецепты")
}

// MARK: - CategoriesViewController
// CategoriesViewController - это экран для выбора категории рецептов
// Показывает список всех категорий (Завтрак, Обед, Десерты и т.д.) и позволяет выбрать одну из них для фильтрации рецептов
class CategoriesViewController: UIViewController {
    
    // Делегат для уведомления о выборе категории
    weak var delegate: CategoriesViewControllerDelegate?
    
    // Выбранная категория (nil означает "показать все рецепты")
    var selectedCategory: Category?
    
    // Все доступные категории из базы данных
    private var allCategories: [Category] = []
    
    // Флаг: скрыты ли специальные категории (All Recipes, Favorites, Archive)
    private var isSpecialCategoriesHidden = false
    
    // Флаг: скрыты ли фиксированные категории (Breakfast, Lunch, Dinner)
    private var isFixedCategoriesHidden = false
    
    // Разделяем категории на группы для удобной организации
    // fixedCategories - фиксированные категории (Breakfast, Lunch, Dinner)
    // Их нельзя удалить, но можно скрыть
    private var fixedCategories: [Category] = []
    
    // customCategories - пользовательские категории (можно удалять и переставлять)
    private var customCategories: [Category] = []
    
    // HideMode описывает режимы отображения категорий
    private enum HideMode: Int {
        case showAll = 0 // Показать все категории (иконка: крестик)
        case hideSpecial = 1 // Скрыть специальные (All Recipes, Favorites, Archive) (крестик в круге)
        case hideSpecialAndFixed = 2 // Скрыть специальные И фиксированные (вилка и нож)
    }
    
    private var currentHideMode: HideMode {
        if isFixedCategoriesHidden {
            return .hideSpecialAndFixed
        } else if isSpecialCategoriesHidden {
            return .hideSpecial
        }
        return .showAll
    }
    
    // Section - это секции таблицы (разделы)
    // CaseIterable означает, что можно получить все значения через .allCases
    private enum Section: Int, CaseIterable {
        case allRecipes = 0 // Секция "Все рецепты"
        case fixedCategories = 1 // Секция фиксированных категорий
        case customCategories = 2 // Секция пользовательских категорий
        case specialCategories = 3 // Секция специальных категорий (Favorites, Archive)
    }
    
    // lazy var - ленивое свойство: создаётся только при первом обращении
    // UITableView - это таблица для отображения списка категорий
    // .insetGrouped - стиль таблицы с закруглёнными группами (как в Настройках iOS)
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        // translatesAutoresizingMaskIntoConstraints = false - используем Auto Layout
        tableView.translatesAutoresizingMaskIntoConstraints = false
        // Регистрируем тип ячейки для переиспользования
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CategoryCell")
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        loadCategories()
        loadSettings()
        setupTableView()
        setupConstraints()
        setupNavigationBar()
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        
        // Создаем кастомный titleView для точного центрирования
        let titleLabel = UILabel()
        titleLabel.text = "CATEGORIES"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.sizeToFit()
        
        // Создаем контейнер для центрирования
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        navigationItem.titleView = containerView
    }
    
    private func setupNavigationBar() {
        // UIBarButtonItem - это кнопка в навигационной панели (вверху экрана)
        let hideButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self, // Кто будет обрабатывать нажатие (этот контроллер)
            // #selector - это способ указать метод для вызова
            // @objc означает, что метод доступен из Objective-C (нужно для #selector)
            // АНАЛОГИЯ: Как адрес функции - "когда нажмут кнопку, вызови этот метод"
            action: #selector(didTapHideButton)
        )
        
        let editButton = UIBarButtonItem(
            image: UIImage(systemName: "pencil"),
            style: .plain,
            target: self,
            action: #selector(didTapEditButton)
        )
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add, // Системная иконка "плюс"
            target: self,
            action: #selector(didTapAddCategory)
        )
        // rightBarButtonItems - массив кнопок справа в навигационной панели
        // Порядок важен: первая кнопка - самая правая
        navigationItem.rightBarButtonItems = [addButton, editButton, hideButton]
        updateHideButton()
    }
    
    // @objc - делает метод доступным из Objective-C runtime
    // Нужно для #selector (указания метода как действия кнопки)
    @objc private func didTapEditButton() {
        // setEditing - включает/выключает режим редактирования таблицы
        // !tableView.isEditing - инвертирует текущее состояние
        // Если isEditing = true, становится false, и наоборот
        tableView.setEditing(!tableView.isEditing, animated: true)
        updateEditButton()
    }
    
    private func updateEditButton() {
        // if var - это условие с ИЗМЕНЯЕМОЙ переменной
        // Разница между if let и if var:
        // - if let создаёт КОНСТАНТУ (нельзя изменить)
        // - if var создаёт ПЕРЕМЕННУЮ (можно изменить)
        // Здесь нужен var, потому что мы изменяем массив rightBarButtonItems
        
        // rightBarButtonItems.count >= 3 - проверяем, что есть минимум 3 кнопки
        // Это защита от ошибок: если кнопок меньше, мы не сможем обратиться к индексу [1]
        if var rightBarButtonItems = navigationItem.rightBarButtonItems,
           rightBarButtonItems.count >= 3 {
            if tableView.isEditing {
                // Режим редактирования включён - показываем кнопку "Готово" (галочка)
                let doneButton = UIBarButtonItem(
                    image: UIImage(systemName: "checkmark"),
                    style: .plain,
                    target: self,
                    action: #selector(didTapEditButton)
                )
                // [1] - это индекс второй кнопки в массиве (индексы начинаются с 0)
                // 0 = addButton, 1 = editButton, 2 = hideButton
                // Заменяем editButton на doneButton
                rightBarButtonItems[1] = doneButton
            } else {
                // Режим редактирования выключен - показываем кнопку "Редактировать" (карандаш)
                let editButton = UIBarButtonItem(
                    image: UIImage(systemName: "pencil"),
                    style: .plain,
                    target: self,
                    action: #selector(didTapEditButton)
                )
                rightBarButtonItems[1] = editButton
            }
            // Применяем изменённый массив к навигационной панели
            navigationItem.rightBarButtonItems = rightBarButtonItems
        }
    }
    
    @objc private func didTapHideButton() {
        // Переключаем режимы: showAll -> hideSpecial -> hideSpecialAndFixed -> showAll
        switch currentHideMode {
        case .showAll:
            isSpecialCategoriesHidden = true
            isFixedCategoriesHidden = false
        case .hideSpecial:
            isSpecialCategoriesHidden = true
            isFixedCategoriesHidden = true
        case .hideSpecialAndFixed:
            isSpecialCategoriesHidden = false
            isFixedCategoriesHidden = false
        }
        
        saveSettings()
        updateHideButton()
        tableView.reloadData()
    }
    
    private func loadSettings() {
        isSpecialCategoriesHidden = CoreDataManager.shared.isSpecialCategoriesHidden()
        // Для isFixedCategoriesHidden используем UserDefaults
        isFixedCategoriesHidden = UserDefaults.standard.bool(forKey: "isFixedCategoriesHidden")
    }
    
    private func saveSettings() {
        CoreDataManager.shared.saveSpecialCategoriesHidden(isSpecialCategoriesHidden)
        UserDefaults.standard.set(isFixedCategoriesHidden, forKey: "isFixedCategoriesHidden")
    }
    
    private func updateHideButton() {
        if let rightBarButtonItems = navigationItem.rightBarButtonItems,
           rightBarButtonItems.count >= 3 {
            let hideButton = rightBarButtonItems[2]
            
            switch currentHideMode {
            case .showAll:
                hideButton.image = UIImage(systemName: "xmark")
            case .hideSpecial:
                hideButton.image = UIImage(systemName: "xmark.circle")
            case .hideSpecialAndFixed:
                hideButton.image = UIImage(systemName: "fork.knife")
            }
            hideButton.tintColor = .label
        }
    }
    
    @objc private func didTapAddCategory() {
        let alert = UIAlertController(title: "New Category", message: "Enter category name", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Category name"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let textField = alert.textFields?.first,
                  let name = textField.text,
                  !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                return
            }
            
            // Находим максимальный order среди пользовательских категорий
            let maxOrder = self?.customCategories.map { $0.order }.max() ?? -1
            let category = Category(name: name.trimmingCharacters(in: .whitespaces), isDefault: false, order: maxOrder + 1)
            RecipesRepository.shared.saveCategory(category)
            self?.loadCategories()
        })
        
        present(alert, animated: true)
    }
    
    private func loadCategories() {
        allCategories = RecipesRepository.shared.getAllCategories()
        
        // Разделяем на фиксированные и пользовательские
        fixedCategories = allCategories.filter { ["Breakfast", "Lunch", "Dinner"].contains($0.name) }
            .sorted { $0.order < $1.order }
        
        customCategories = allCategories.filter { !["Breakfast", "Lunch", "Dinner"].contains($0.name) }
            .sorted { $0.order < $1.order }
        
        tableView.reloadData()
    }
    
    private func saveCategoryOrder() {
        // Сохраняем порядок пользовательских категорий
        for (index, category) in customCategories.enumerated() {
            var updatedCategory = category
            updatedCategory.order = Int32(index)
            RecipesRepository.shared.saveCategory(updatedCategory)
        }
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension CategoriesViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if isFixedCategoriesHidden {
            // Скрыты All Recipes, Favorites, Archive и Fixed Categories - только Custom
            return 1
        } else if isSpecialCategoriesHidden {
            // Скрыты All Recipes, Favorites, Archive - только Fixed и Custom
            return 2
        }
        // Показаны все секции
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFixedCategoriesHidden {
            // Только Custom Categories
            return customCategories.count
        } else if isSpecialCategoriesHidden {
            // Fixed и Custom Categories
            switch section {
            case 0:
                return fixedCategories.count
            case 1:
                return customCategories.count
            default:
                return 0
            }
        }
        
        // Все секции видны
        let sectionType = Section(rawValue: section) ?? .allRecipes
        
        switch sectionType {
        case .allRecipes:
            return 1
        case .fixedCategories:
            return fixedCategories.count
        case .customCategories:
            return customCategories.count
        case .specialCategories:
            return 2 // Favorites, Archive
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        
        // Очищаем ячейку перед настройкой
        cell.textLabel?.text = nil
        cell.textLabel?.attributedText = nil
        cell.detailTextLabel?.text = nil
        cell.accessoryType = .none
        
        if isFixedCategoriesHidden {
            // Только Custom Categories
            let category = customCategories[indexPath.row]
            cell.textLabel?.text = category.name
            cell.detailTextLabel?.text = nil
            cell.accessoryType = selectedCategory?.id == category.id ? .checkmark : .none
        } else if isSpecialCategoriesHidden {
            // Fixed и Custom Categories
            switch indexPath.section {
            case 0:
                let category = fixedCategories[indexPath.row]
                cell.textLabel?.text = category.name
                cell.detailTextLabel?.text = nil
                cell.accessoryType = selectedCategory?.id == category.id ? .checkmark : .none
            case 1:
                let category = customCategories[indexPath.row]
                cell.textLabel?.text = category.name
                cell.detailTextLabel?.text = nil
                cell.accessoryType = selectedCategory?.id == category.id ? .checkmark : .none
            default:
                break
            }
        } else {
            let sectionType = Section(rawValue: indexPath.section) ?? .allRecipes
            
            switch sectionType {
            case .allRecipes:
                cell.textLabel?.text = "All Recipes"
                cell.detailTextLabel?.text = nil
                
                // Если selectedCategory == nil (ничего не выбрано), показываем галочку. Иначе (что-то выбрано), не показываем галочку
                cell.accessoryType = selectedCategory == nil ? .checkmark : .none
                
            case .fixedCategories:
                // indexPath.row - номер строки в секции (0, 1, 2, ...)
                // Получаем категорию из массива по индексу
                let category = fixedCategories[indexPath.row]
                cell.textLabel?.text = category.name
                cell.detailTextLabel?.text = nil
                
                // Опциональная цепочка: selectedCategory?.id
                // Если selectedCategory = nil, всё выражение вернёт nil
                // Если selectedCategory != nil, получим id
                // Затем сравниваем с category.id
                // Тернарный оператор: если равны - показываем галочку, иначе - нет
                cell.accessoryType = selectedCategory?.id == category.id ? .checkmark : .none
                
            case .customCategories:
                let category = customCategories[indexPath.row]
                cell.textLabel?.text = category.name
                cell.detailTextLabel?.text = nil
                cell.accessoryType = selectedCategory?.id == category.id ? .checkmark : .none
                
            case .specialCategories:
                if indexPath.row == 0 {
                    
                    // Favorites
                    cell.textLabel?.text = "Favorites"
                    
                    // Получаем количество избранных рецептов
                    let favoriteCount = RecipesRepository.shared.getFavoriteRecipes().count
                    
                    cell.detailTextLabel?.text = favoriteCount > 0 ? "\(favoriteCount)" : nil
                    
                    // UUID(uuidString:) - создаёт UUID из строки
                    // Это специальный UUID для категории "Избранное" (не настоящая категория в базе)
                    let favoriteCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")
                    
                    // Сравниваем выбранную категорию с ID избранного
                    // Опциональная цепочка: если selectedCategory = nil, вернётся nil, сравнение = false
                    let isFavoriteSelected = selectedCategory?.id == favoriteCategoryId
                    cell.accessoryType = isFavoriteSelected ? .checkmark : .none
                } else if indexPath.row == 1 {
                    
                    // Archive
                    cell.textLabel?.text = "Archive"
                    
                    // Получаем количество архивированных рецептов
                    let archiveCount = RecipesRepository.shared.getAllRecipes(archived: true).count
                    
                    // Показываем количество, если есть архивированные рецепты
                    cell.detailTextLabel?.text = archiveCount > 0 ? "\(archiveCount)" : nil
                    let archiveCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")
                    let isArchiveSelected = selectedCategory?.id == archiveCategoryId
                    cell.accessoryType = isArchiveSelected ? .checkmark : .none
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if isFixedCategoriesHidden {
            // Можно перемещать только в секции пользовательских категорий (секция 0)
            return indexPath.section == 0
        } else if isSpecialCategoriesHidden {
            // Можно перемещать только в секции пользовательских категорий (секция 1)
            return indexPath.section == 1
        }
        // Section(rawValue:) - это FAILABLE INITIALIZER enum
        // Пытается создать Section из числа (rawValue)
        // Если indexPath.section = 0, создастся .allRecipes
        // Если indexPath.section = 1, создастся .fixedCategories
        // Если число не соответствует ни одному case, вернётся nil
        
        // Если Section(rawValue:) вернёт nil, используем .allRecipes по умолчанию
        // АНАЛОГИЯ: "Если не получилось определить тип секции, считай что это 'Все рецепты'"
        let sectionType = Section(rawValue: indexPath.section) ?? .allRecipes
        
        // Можно перемещать только в секции пользовательских категорий
        return sectionType == .customCategories
    }
    
    // moveRowAt - вызывается, когда пользователь переместил ячейку (перетащил её)
    // sourceIndexPath - откуда переместили (исходная позиция)
    // destinationIndexPath - куда переместили (новая позиция)
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // Определяем индекс секции с пользовательскими категориями
        // Это зависит от того, какие секции скрыты
        let customSectionIndex: Int
        if isFixedCategoriesHidden {
            customSectionIndex = 0
        } else if isSpecialCategoriesHidden {
            customSectionIndex = 1
        } else {
            // .rawValue - получаем числовое значение enum
            // Section.customCategories.rawValue вернёт 2 (как определено в enum)
            customSectionIndex = Section.customCategories.rawValue
        }
        
        // guard - проверяем, что перемещение происходит внутри одной секции
        // Нельзя перемещать категорию из одной секции в другую
        guard sourceIndexPath.section == customSectionIndex,
              destinationIndexPath.section == customSectionIndex else {
            // Если секции не совпадают, прекращаем выполнение (ничего не делаем)
            return
        }
        
        // remove(at:) - удаляет элемент из массива по индексу и ВОЗВРАЩАЕТ его
        let movedCategory = customCategories.remove(at: sourceIndexPath.row)
        
        // insert(_:at:) - вставляет элемент в массив по указанному индексу
        customCategories.insert(movedCategory, at: destinationIndexPath.row)
        
        saveCategoryOrder()
    }
}

extension CategoriesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if isFixedCategoriesHidden {
            // Только Custom Categories
            selectedCategory = customCategories[indexPath.row]
        } else if isSpecialCategoriesHidden {
            // Fixed и Custom Categories
            switch indexPath.section {
            case 0:
                selectedCategory = fixedCategories[indexPath.row]
            case 1:
                selectedCategory = customCategories[indexPath.row]
            default:
                break
            }
        } else {
            let sectionType = Section(rawValue: indexPath.section) ?? .allRecipes
            
            switch sectionType {
            case .allRecipes:
                selectedCategory = nil
                
            case .fixedCategories:
                selectedCategory = fixedCategories[indexPath.row]
                
            case .customCategories:
                selectedCategory = customCategories[indexPath.row]
                
            case .specialCategories:
                if indexPath.row == 0 {
                    selectedCategory = Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(), name: "Favorites", isDefault: false, order: 0)
                } else {
                    selectedCategory = Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID(), name: "Archive", isDefault: false, order: 0)
                }
            }
        }
        
        // Вызываем делегата, чтобы уведомить о выборе категории
        // ? - опциональная цепочка: если delegate = nil, ничего не произойдёт
        delegate?.didSelectCategory(selectedCategory)
        
        // Перезагружаем таблицу, чтобы показать новую галочку у выбранной категории
        tableView.reloadData()
        
        // DispatchQueue.main.asyncAfter - выполнить код через определённое время
        // .main - главная очередь (UI поток)
        // asyncAfter - асинхронно через указанное время
        // deadline: .now() + 0.3 - через 0.3 секунды от текущего момента
        // Как таймер - "через 0.3 секунды сделай это"
        // Зачем задержка? Чтобы пользователь увидел галочку перед закрытием экрана
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // popViewController - возвращает на предыдущий экран в навигационном стеке
            // АНАЛОГИЯ: Как кнопка "Назад" в браузере
            // animated: true - с анимацией (плавный переход)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let customSectionIndex: Int
            if isFixedCategoriesHidden {
                customSectionIndex = 0
            } else if isSpecialCategoriesHidden {
                customSectionIndex = 1
            } else {
                customSectionIndex = Section.customCategories.rawValue
            }
            
            if indexPath.section == customSectionIndex {
                let category = customCategories[indexPath.row]
                RecipesRepository.shared.deleteCategory(category)
                customCategories.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                if selectedCategory?.id == category.id {
                    selectedCategory = nil
                    delegate?.didSelectCategory(nil)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let customSectionIndex: Int
        if isFixedCategoriesHidden {
            customSectionIndex = 0
        } else if isSpecialCategoriesHidden {
            customSectionIndex = 1
        } else {
            customSectionIndex = Section.customCategories.rawValue
        }
        // Можно удалять только пользовательские категории
        return indexPath.section == customSectionIndex
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let customSectionIndex: Int
        if isFixedCategoriesHidden {
            customSectionIndex = 0
        } else if isSpecialCategoriesHidden {
            customSectionIndex = 1
        } else {
            customSectionIndex = Section.customCategories.rawValue
        }
        if indexPath.section == customSectionIndex {
            return .delete
        }
        return .none
    }
}

//
//  RecipeEditViewController.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

// MARK: - RecipeEditViewControllerDelegate
// Протокол для уведомления о сохранении рецепта
protocol RecipeEditViewControllerDelegate: AnyObject {
    func didSaveRecipe() // Рецепт был сохранён
}

// MARK: - RecipeEditViewController
// RecipeEditViewController - это экран для создания или редактирования рецепта
// Позволяет ввести название, инструкции, добавить фото, ингредиенты, категории и т.д.
// Если recipe == nil, создаётся новый рецепт; если не nil - редактируется существующий
class RecipeEditViewController: UIViewController {
    
    // Делегат для уведомления о сохранении рецепта
    weak var delegate: RecipeEditViewControllerDelegate?
    
    // Рецепт для редактирования (nil = создаём новый рецепт)
    private var recipe: Recipe?
    
    // Список ингредиентов рецепта
    private var ingredients: [Ingredient] = []
    
    // Set выбранных категорий (используем UUID для идентификации)
    private var selectedCategories: Set<UUID> = []
    private var allCategories: [Category] = []
    
    // Состояние раскрытости секций
    private var isPhotoExpanded = false
    private var isIngredientsExpanded = false
    private var isCategoriesExpanded = false
    private var isTagsExpanded = false
    private var isAdditionalExpanded = false
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(RecipeEditNameCell.self, forCellReuseIdentifier: RecipeEditNameCell.identifier)
        tableView.register(RecipeEditInstructionsCell.self, forCellReuseIdentifier: RecipeEditInstructionsCell.identifier)
        tableView.register(RecipeEditPhotoCell.self, forCellReuseIdentifier: RecipeEditPhotoCell.identifier)
        tableView.register(RecipeEditDifficultyCell.self, forCellReuseIdentifier: RecipeEditDifficultyCell.identifier)
        tableView.register(RecipeEditTagsCell.self, forCellReuseIdentifier: RecipeEditTagsCell.identifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()
    
    // ВАЖНО: Теги теперь управляются глобально через TagsManager
    // Это означает, что если добавил тег в одном рецепте, он появится и в других
    // TagsManager.shared - это Singleton, который хранит все теги приложения
    
    // Выбранные теги для текущего рецепта (отмеченные галочкой)
    private var selectedTags: Set<String> = []
    
    // ВАЖНО: Это COMPUTED PROPERTY (вычисляемое свойство)
    // В отличие от обычного свойства, это свойство НЕ хранит значение
    // Оно ВЫЧИСЛЯЕТ значение каждый раз при обращении
    
    // АНАЛОГИЯ: Как калькулятор - не хранит результат, а вычисляет его каждый раз
    // Обычное свойство: var x = 5 (хранит 5)
    // Computed property: var x: Int { return 2 + 3 } (вычисляет 5 каждый раз)
    
    // Зачем computed property здесь?
    // availableTags должен всегда быть актуальным - если удалили тег, он должен исчезнуть
    // Если бы это было обычное свойство, нужно было бы обновлять его вручную каждый раз
    private var availableTags: [String] {
        // Получаем все доступные теги из глобального менеджера
        // TagsManager.shared.getAllAvailableTags() возвращает:
        // - Стандартные теги (Vegetarian, Vegan и т.д.)
        // - Пользовательские теги (добавленные пользователем)
        // - Исключает удалённые теги
        return TagsManager.shared.getAllAvailableTags()
    }
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Delete", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(didTapDeleteButton), for: .touchUpInside)
        return button
    }()
    
    private var imageData: Data?
    private var imageURL: String?
    private var difficultyValue: Int = UISegmentedControl.noSegment
    private var recipeName: String = ""
    private var recipeInstructions: String = ""
    
    // Sections
    private enum Section: Int, CaseIterable {
        case basicInfo = 0
        case photo = 1
        case ingredients = 2
        case extra = 3
        case categories = 4
        case tags = 5
    }
    
    init(recipe: Recipe? = nil) {
        self.recipe = recipe
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationBar()
        loadCategories()
        loadRecipeData()
        setupLayout()
        setupKeyboardDismissal()
    }
    
    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Добавляем кнопку Delete как футер таблицы, если редактируем существующий рецепт
        if recipe != nil && tableView.tableFooterView == nil {
            setupDeleteButtonFooter()
        }
        
        // Обновляем размер футера после layout
        if let footerView = tableView.tableFooterView {
            let width = tableView.bounds.width
            if width > 0 {
                let size = footerView.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
                if footerView.frame.size.height != size.height || footerView.frame.size.width != width {
                    footerView.frame.size = CGSize(width: width, height: size.height)
                    tableView.tableFooterView = footerView
                }
            }
        }
    }
    
    private func setupView() {
        view.backgroundColor = .systemGroupedBackground
        title = recipe == nil ? "New Recipe" : "Edit Recipe"
    }
    
    private func setupNavigationBar() {
        let saveButton = UIBarButtonItem(
            image: UIImage(systemName: "checkmark"),
            style: .plain,
            target: self,
            action: #selector(didTapSave)
        )
        navigationItem.rightBarButtonItem = saveButton
    }
    
    // ЗАГРУЗКА КАТЕГОРИЙ
    // ИСПРАВЛЕНИЕ: Категории теперь правильно сортируются по полю order
    // Когда пользователь меняет порядок категорий в CategoriesViewController,
    // поле order обновляется, и здесь категории отображаются в правильном порядке
    // 
    // ПРАВИЛЬНЫЙ ПОРЯДОК КАТЕГОРИЙ ПО УМОЛЧАНИЮ:
    // 1. Breakfast (Завтрак) - order: 0
    // 2. Lunch (Обед) - order: 1
    // 3. Dinner (Ужин) - order: 2
    // 4. Desserts (Десерты) - order: 3 (после Ужина, но перед Супами)
    // 5. Soups (Супы) - order: 4
    // 6. Salads (Салаты) - order: 5
    // 7. Beverages (Напитки) - order: 6
    private func loadCategories() {
        // getAllCategories() уже возвращает категории, отсортированные по order
        // Сначала по полю order (порядок, заданный пользователем),
        // затем по имени (если order одинаковый)
        allCategories = RecipesRepository.shared.getAllCategories()
        
        // ВАЖНО: RecipesRepository.shared.getAllCategories() уже сортирует категории:
        // 1. По полю order (ascending - по возрастанию)
        // 2. По имени (если order одинаковый)
        // Это означает, что категории будут отображаться в том порядке,
        // в котором пользователь их расположил в CategoriesViewController
    }
    
    private func loadRecipeData() {
        if let recipe = recipe {
            recipeName = recipe.name
            recipeInstructions = recipe.recipeInstructions ?? ""
            ingredients = recipe.ingredients
            selectedCategories = Set(recipe.categories.map { $0.id })
            imageData = recipe.imageData
            imageURL = recipe.imageURL
            
            if let difficulty = recipe.difficulty {
                switch difficulty.lowercased() {
                case "easy":
                    difficultyValue = 0
                case "medium":
                    difficultyValue = 1
                case "hard":
                    difficultyValue = 2
                default:
                    difficultyValue = UISegmentedControl.noSegment
                }
            } else {
                difficultyValue = UISegmentedControl.noSegment
            }
            // Загружаем выбранные теги из рецепта
            selectedTags = Set(recipe.tags)
            
            // ВАЖНО: Теперь пользовательские теги хранятся глобально в TagsManager
            // Не нужно загружать их из рецепта - они уже есть в TagsManager.shared
            // Если рецепт содержит тег, которого нет в TagsManager, добавляем его
            for tag in recipe.tags {
                // Если тег не стандартный и не в списке пользовательских, добавляем его
                if !TagsManager.shared.defaultTags.contains(tag) {
                    TagsManager.shared.addCustomTag(tag)
                }
            }
        }
    }
    
    private func setupLayout() {
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Футер будет добавлен в viewDidLayoutSubviews когда размеры будут известны
    }
    
    private func setupDeleteButtonFooter() {
        let footerView = UIView()
        footerView.backgroundColor = .clear
        
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        footerView.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            deleteButton.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 16),
            deleteButton.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 16),
            deleteButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -16),
            deleteButton.heightAnchor.constraint(equalToConstant: 50),
            deleteButton.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: -16)
        ])
        
        // Устанавливаем начальный размер футера с правильной шириной
        footerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width > 0 ? tableView.bounds.width : view.bounds.width, height: 82)
        tableView.tableFooterView = footerView
    }
    
    @objc private func didTapSave() {
        // Обновляем значения из видимых ячеек перед сохранением
        if let nameCell = tableView.cellForRow(at: IndexPath(row: 0, section: Section.basicInfo.rawValue)) as? RecipeEditNameCell {
            recipeName = nameCell.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        }
        
        if let instructionsCell = tableView.cellForRow(at: IndexPath(row: 1, section: Section.basicInfo.rawValue)) as? RecipeEditInstructionsCell {
            recipeInstructions = instructionsCell.textView.text.trimmingCharacters(in: .whitespaces)
        }
        
        if let difficultyCell = tableView.cellForRow(at: IndexPath(row: 0, section: Section.extra.rawValue)) as? RecipeEditDifficultyCell {
            difficultyValue = difficultyCell.segmentedControl.selectedSegmentIndex
        }
        
        guard !recipeName.isEmpty else {
            showAlert(title: "Error", message: "Enter recipe name")
            return
        }
        
        let name = recipeName
        let instructions = recipeInstructions
        
        let categories = allCategories.filter { selectedCategories.contains($0.id) }
        
        var difficulty: String? = nil
        switch difficultyValue {
        case 0:
            difficulty = "easy"
        case 1:
            difficulty = "medium"
        case 2:
            difficulty = "hard"
        default:
            difficulty = nil
        }
        
        let tags = Array(selectedTags)
        
        let recipeToSave: Recipe
        if let existingRecipe = recipe {
            recipeToSave = Recipe(
                id: existingRecipe.id,
                name: name,
                recipeInstructions: instructions.isEmpty ? nil : instructions,
                imageData: imageData,
                imageURL: imageURL,
                ingredients: ingredients,
                categories: categories,
                isArchived: existingRecipe.isArchived,
                isFavorite: existingRecipe.isFavorite,
                createdAt: existingRecipe.createdAt,
                difficulty: difficulty,
                tags: tags
            )
        } else {
            recipeToSave = Recipe(
                name: name,
                recipeInstructions: instructions.isEmpty ? nil : instructions,
                imageData: imageData,
                imageURL: imageURL,
                ingredients: ingredients,
                categories: categories,
                difficulty: difficulty,
                tags: tags
            )
        }
        
        RecipesRepository.shared.saveRecipe(recipeToSave)
        delegate?.didSaveRecipe()
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func didTapDeleteButton() {
        guard let recipe = recipe else { return }
        
        let alert = UIAlertController(
            title: "Delete recipe?",
            message: "Recipe will be moved to archive",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            RecipesRepository.shared.archiveRecipe(recipe)
            self?.delegate?.didSaveRecipe()
            self?.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    @objc private func didTapAddImageButton() {
        presentImageSourceOptions(showDeleteOption: false, sourceView: nil)
    }
    
    @objc private func didTapPhotoImageView(_ gesture: UITapGestureRecognizer) {
        guard let imageView = gesture.view as? UIImageView else { return }
        presentImageSourceOptions(showDeleteOption: true, sourceView: imageView)
    }
    
    private func presentImageSourceOptions(showDeleteOption: Bool, sourceView: UIView?) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        })
        
        alert.addAction(UIAlertAction(title: "Search Unsplash", style: .default) { [weak self] _ in
            self?.presentUnsplashSearch()
        })
        
        if showDeleteOption {
            alert.addAction(UIAlertAction(title: "Delete Photo", style: .destructive) { [weak self] _ in
                self?.deletePhoto()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            if let sourceView = sourceView {
                // Преобразуем координаты imageView в координаты view контроллера
                let rectInView = sourceView.convert(sourceView.bounds, to: view)
                popover.sourceView = view
                popover.sourceRect = rectInView
            } else {
                popover.sourceView = view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            }
        }
        
        present(alert, animated: true)
    }
    
    private func deletePhoto() {
        imageData = nil
        imageURL = nil
        tableView.reloadSections([Section.photo.rawValue], with: .automatic)
    }
    
    private func presentUnsplashSearch() {
        // Обновляем recipeName из ячейки если она видима
        if let nameCell = tableView.cellForRow(at: IndexPath(row: 0, section: Section.basicInfo.rawValue)) as? RecipeEditNameCell {
            recipeName = nameCell.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        }
        let searchQuery = recipeName.isEmpty ? "food recipe" : recipeName
        let searchVC = UnsplashImageSearchViewController(searchQuery: searchQuery)
        searchVC.delegate = self
        navigationController?.pushViewController(searchVC, animated: true)
    }
    
    // ДОБАВЛЕНИЕ НОВОГО ИНГРЕДИЕНТА
    // Когда пользователь нажимает "+ Add Ingredient", открывается диалог для ввода названия и количества
    @objc private func didTapAddIngredientButton() {
        let alert = UIAlertController(title: "New Ingredient", message: nil, preferredStyle: .alert)
        
        // Добавляем текстовое поле для названия ингредиента
        alert.addTextField { textField in
            textField.placeholder = "Ingredient name"
        }
        
        // Добавляем текстовое поле для количества (опционально)
        alert.addTextField { textField in
            textField.placeholder = "Amount (optional)"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let nameField = alert.textFields?[0],
                  let name = nameField.text?.trimmingCharacters(in: .whitespaces),
                  !name.isEmpty else {
                return
            }
            
            // Получаем количество (может быть пустым)
            let amount = alert.textFields?[1].text?.trimmingCharacters(in: .whitespaces)
            // Создаём новый ингредиент
            let ingredient = Ingredient(name: name, amount: amount?.isEmpty == false ? amount : nil)
            // Добавляем в массив ингредиентов
            self?.ingredients.append(ingredient)
            // Перезагружаем секцию ингредиентов
            self?.tableView.reloadSections([Section.ingredients.rawValue], with: .automatic)
        })
        
        present(alert, animated: true)
    }
    
    // РЕДАКТИРОВАНИЕ ИНГРЕДИЕНТА
    // ИСПРАВЛЕНИЕ: Добавлена возможность редактирования ингредиентов
    // Позволяет изменить название и количество существующего ингредиента
    private func editIngredient(at index: Int) {
        // Проверяем, что индекс валидный
        guard index < ingredients.count else { return }
        
        // Получаем ингредиент для редактирования
        let ingredient = ingredients[index]
        
        // Создаём диалог для редактирования
        let alert = UIAlertController(title: "Edit Ingredient", message: nil, preferredStyle: .alert)
        
        // Добавляем текстовое поле с текущим названием ингредиента
        alert.addTextField { textField in
            textField.placeholder = "Ingredient name"
            textField.text = ingredient.name
        }
        
        // Добавляем текстовое поле с текущим количеством
        alert.addTextField { textField in
            textField.placeholder = "Amount (optional)"
            textField.text = ingredient.amount
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let nameField = alert.textFields?[0],
                  let name = nameField.text?.trimmingCharacters(in: .whitespaces),
                  !name.isEmpty else {
                return
            }
            
            // Получаем новое количество (может быть пустым)
            let amount = alert.textFields?[1].text?.trimmingCharacters(in: .whitespaces)
            
            // Создаём обновлённый ингредиент с тем же ID
            // ID остаётся прежним, чтобы сохранить связь с базой данных (если нужно)
            let updatedIngredient = Ingredient(
                id: ingredient.id,
                name: name,
                amount: amount?.isEmpty == false ? amount : nil
            )
            
            // Заменяем старый ингредиент на обновлённый
            self.ingredients[index] = updatedIngredient
            
            // Перезагружаем секцию ингредиентов
            self.tableView.reloadSections([Section.ingredients.rawValue], with: .automatic)
        })
        
        present(alert, animated: true)
    }
    
    @objc private func didTapAddCategoryButton() {
        let alert = UIAlertController(title: "New Category", message: "Enter category name", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Category name"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let textField = alert.textFields?.first,
                  let name = textField.text?.trimmingCharacters(in: .whitespaces),
                  !name.isEmpty else {
                return
            }
            
            if let existingCategory = self?.allCategories.first(where: { $0.name.lowercased() == name.lowercased() }) {
                self?.selectedCategories.insert(existingCategory.id)
                self?.tableView.reloadSections([Section.categories.rawValue], with: .automatic)
            } else {
                let category = Category(name: name)
                RecipesRepository.shared.saveCategory(category)
                self?.loadCategories()
                self?.selectedCategories.insert(category.id)
                self?.tableView.reloadSections([Section.categories.rawValue], with: .automatic)
            }
        })
        
        present(alert, animated: true)
    }
    
    // ДОБАВЛЕНИЕ НОВОГО ТЕГА
    // Когда пользователь нажимает "+ Add Tag", открывается диалог для ввода названия тега
    @objc private func didTapAddTagButton() {
        let alert = UIAlertController(title: "New Tag", message: "Enter tag name", preferredStyle: .alert)
        
        // Добавляем текстовое поле для ввода названия тега
        alert.addTextField { textField in
            textField.placeholder = "Tag name"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let textField = alert.textFields?.first,
                  let name = textField.text?.trimmingCharacters(in: .whitespaces),
                  !name.isEmpty else {
                return
            }
            
            // Проверяем, существует ли уже такой тег (без учёта регистра)
            let tagExists = self.availableTags.contains(where: { $0.lowercased() == name.lowercased() })
            
            if !tagExists {
                // Добавляем тег в глобальное хранилище (TagsManager)
                // Теперь тег будет доступен во всех рецептах
                TagsManager.shared.addCustomTag(name)
            }
            
            // Добавляем тег в выбранные для текущего рецепта
            self.selectedTags.insert(name)
            
            // Перезагружаем секцию тегов
            self.tableView.reloadSections([Section.tags.rawValue], with: .automatic)
            
            // ИСПРАВЛЕНИЕ БАГА: Прокручиваем коллекцию к новому тегу, чтобы его было видно
            // Находим индекс нового тега в списке
            if let newTagIndex = self.availableTags.firstIndex(of: name) {
                // Находим ячейку с коллекцией тегов
                if let tagsCell = self.tableView.cellForRow(at: IndexPath(row: 0, section: Section.tags.rawValue)) as? RecipeEditTagsCell {
                    // Прокручиваем коллекцию к новому тегу
                    let indexPath = IndexPath(item: newTagIndex, section: 0)
                    tagsCell.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private var hasPhoto: Bool {
        return imageData != nil || imageURL != nil
    }
}

// MARK: - UITableViewDataSource
extension RecipeEditViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .basicInfo:
            return 2
        case .photo:
            return isPhotoExpanded ? 1 : 0
        case .ingredients:
            return isIngredientsExpanded ? max(ingredients.count, 1) + 1 : 0
        case .extra:
            return isAdditionalExpanded ? 1 : 0
        case .categories:
            return isCategoriesExpanded ? allCategories.count + 1 : 0
        case .tags:
            return isTagsExpanded ? 2 : 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil // Все заголовки теперь кастомные
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionType = Section(rawValue: section) else { return nil }
        
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let titleLabel = UILabel()
        titleLabel.textColor = .secondaryLabel
        
        var isExpanded = false
        var showChevron = false
        
        switch sectionType {
        case .basicInfo:
            titleLabel.text = "Recipe"
            titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        case .photo:
            titleLabel.text = "Photo"
            titleLabel.font = .systemFont(ofSize: 18, weight: .heavy)
            isExpanded = isPhotoExpanded
            showChevron = true
        case .ingredients:
            titleLabel.text = "Ingredients"
            titleLabel.font = .systemFont(ofSize: 18, weight: .heavy)
            isExpanded = isIngredientsExpanded
            showChevron = true
        case .extra:
            titleLabel.text = "Extra"
            titleLabel.font = .systemFont(ofSize: 18, weight: .heavy)
            isExpanded = isAdditionalExpanded
            showChevron = true
        case .categories:
            titleLabel.text = "Categories"
            titleLabel.font = .systemFont(ofSize: 18, weight: .heavy)
            isExpanded = isCategoriesExpanded
            showChevron = true
        case .tags:
            titleLabel.text = "Tags"
            titleLabel.font = .systemFont(ofSize: 18, weight: .heavy)
            isExpanded = isTagsExpanded
            showChevron = true
        }
        
        headerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        if showChevron {
            let chevronLabel = UILabel()
            chevronLabel.text = isExpanded ? "▼" : "▶"
            chevronLabel.font = .systemFont(ofSize: 12)
            chevronLabel.textColor = .secondaryLabel
            
            headerView.addSubview(chevronLabel)
            chevronLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                
                chevronLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
                chevronLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
            ])
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapSectionHeader(_:)))
            headerView.addGestureRecognizer(tapGesture)
            headerView.tag = section
        } else {
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
            ])
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40 // Все заголовки теперь имеют одинаковую высоту
    }
    
    @objc private func didTapSectionHeader(_ gesture: UITapGestureRecognizer) {
        guard let headerView = gesture.view,
              let sectionType = Section(rawValue: headerView.tag) else { return }
        
        switch sectionType {
        case .photo:
            isPhotoExpanded.toggle()
        case .ingredients:
            isIngredientsExpanded.toggle()
        case .extra:
            isAdditionalExpanded.toggle()
        case .categories:
            isCategoriesExpanded.toggle()
        case .tags:
            isTagsExpanded.toggle()
        default:
            break
        }
        
        tableView.reloadSections([headerView.tag], with: .automatic)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch sectionType {
        case .basicInfo:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: RecipeEditNameCell.identifier, for: indexPath) as! RecipeEditNameCell
                cell.textField.text = recipeName
                cell.textField.addTarget(self, action: #selector(nameTextFieldDidChange(_:)), for: .editingChanged)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: RecipeEditInstructionsCell.identifier, for: indexPath) as! RecipeEditInstructionsCell
                cell.textView.text = recipeInstructions
                cell.updatePlaceholder()
                cell.textView.delegate = self
                return cell
            }
            
        case .photo:
            let cell = tableView.dequeueReusableCell(withIdentifier: RecipeEditPhotoCell.identifier, for: indexPath) as! RecipeEditPhotoCell
            cell.configure(hasImage: hasPhoto)
            
            // Удаляем старые gesture recognizers
            cell.photoImageView.gestureRecognizers?.forEach { cell.photoImageView.removeGestureRecognizer($0) }
            cell.addPhotoImageView.gestureRecognizers?.forEach { cell.addPhotoImageView.removeGestureRecognizer($0) }
            
            if let imageData = imageData, let image = UIImage(data: imageData) {
                cell.photoImageView.image = image
            } else if let imageURL = imageURL, !imageURL.isEmpty {
                RecipesAPIService.shared.loadImage(from: imageURL) { [weak self] result in
                    DispatchQueue.main.async {
                        if case .success(let image) = result {
                            cell.photoImageView.image = image
                            self?.imageData = image.jpegData(compressionQuality: 0.8)
                        }
                    }
                }
            }
            
            // Добавляем тап на иконку добавления фото или на само фото
            if hasPhoto {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPhotoImageView(_:)))
                cell.photoImageView.addGestureRecognizer(tapGesture)
            } else {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapAddImageButton))
                cell.addPhotoImageView.addGestureRecognizer(tapGesture)
            }
            
            return cell
            
        case .ingredients:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            if indexPath.row < ingredients.count {
                let ingredient = ingredients[indexPath.row]
                cell.textLabel?.text = ingredient.displayText
                cell.textLabel?.textColor = .label
                cell.textLabel?.font = .systemFont(ofSize: 17)
                // ИСПРАВЛЕНИЕ: Добавлен индикатор редактирования, чтобы было понятно, что ингредиент можно редактировать
                // .disclosureIndicator показывает стрелку справа, указывающую, что при нажатии откроется экран редактирования
                cell.accessoryType = .disclosureIndicator
                // ИСПРАВЛЕНИЕ: Изменён selectionStyle на .default, чтобы ячейка визуально реагировала на нажатие
                // Это делает очевидным, что ингредиент можно нажать для редактирования
                cell.selectionStyle = .default
            } else if indexPath.row == ingredients.count {
                cell.textLabel?.text = "+ Add Ingredient"
                cell.textLabel?.textColor = .systemBlue
                cell.textLabel?.font = .systemFont(ofSize: 17)
                cell.accessoryType = .none
                cell.selectionStyle = .default
            }
            return cell
            
        case .extra:
            let cell = tableView.dequeueReusableCell(withIdentifier: RecipeEditDifficultyCell.identifier, for: indexPath) as! RecipeEditDifficultyCell
            cell.segmentedControl.selectedSegmentIndex = difficultyValue
            cell.segmentedControl.addTarget(self, action: #selector(difficultyDidChange(_:)), for: .valueChanged)
            return cell
            
        case .categories:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            if indexPath.row < allCategories.count {
                let category = allCategories[indexPath.row]
                cell.textLabel?.text = category.name
                cell.textLabel?.textColor = .label
                cell.textLabel?.font = .systemFont(ofSize: 17)
                cell.accessoryType = selectedCategories.contains(category.id) ? .checkmark : .none
                cell.selectionStyle = .default
            } else if indexPath.row == allCategories.count {
                cell.textLabel?.text = "+ Add Category"
                cell.textLabel?.textColor = .systemBlue
                cell.textLabel?.font = .systemFont(ofSize: 17)
                cell.accessoryType = .none
                cell.selectionStyle = .default
            }
            return cell
            
        case .tags:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: RecipeEditTagsCell.identifier, for: indexPath) as! RecipeEditTagsCell
                cell.collectionView.dataSource = self
                cell.collectionView.delegate = self
                if let flowLayout = cell.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                    flowLayout.minimumInteritemSpacing = 4
                    flowLayout.minimumLineSpacing = 6
                }
                
                // Удаляем старые gesture recognizers перед добавлением нового
                cell.collectionView.gestureRecognizers?.forEach { gesture in
                    if gesture is UILongPressGestureRecognizer {
                        cell.collectionView.removeGestureRecognizer(gesture)
                    }
                }
                
                // Добавляем долгий тап для удаления тегов
                let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressOnTag(_:)))
                longPressGesture.minimumPressDuration = 0.5
                cell.collectionView.addGestureRecognizer(longPressGesture)
                
                cell.collectionView.reloadData()
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                cell.textLabel?.text = "+ Add Tag"
                cell.textLabel?.textColor = .systemBlue
                cell.textLabel?.font = .systemFont(ofSize: 17)
                cell.accessoryType = .none
                cell.selectionStyle = .default
                return cell
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension RecipeEditViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let sectionType = Section(rawValue: indexPath.section) else { return }
        
        switch sectionType {
        case .ingredients:
            if indexPath.row < ingredients.count {
                // ИСПРАВЛЕНИЕ: Добавлена возможность редактирования ингредиента
                // При нажатии на ингредиент открывается диалог для редактирования
                editIngredient(at: indexPath.row)
            } else if indexPath.row == ingredients.count {
                didTapAddIngredientButton()
            }
        case .extra:
            break
        case .categories:
            if indexPath.row < allCategories.count {
                let category = allCategories[indexPath.row]
                if selectedCategories.contains(category.id) {
                    selectedCategories.remove(category.id)
                } else {
                    selectedCategories.insert(category.id)
                }
                tableView.reloadRows(at: [indexPath], with: .none)
            } else if indexPath.row == allCategories.count {
                didTapAddCategoryButton()
            }
        case .tags:
            if indexPath.row == 1 {
                didTapAddTagButton()
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let sectionType = Section(rawValue: indexPath.section),
              sectionType == .ingredients,
              editingStyle == .delete,
              indexPath.row < ingredients.count else {
            return
        }
        
        ingredients.remove(at: indexPath.row)
        tableView.reloadSections([Section.ingredients.rawValue], with: .automatic)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let sectionType = Section(rawValue: indexPath.section) else { return false }
        return sectionType == .ingredients && indexPath.row < ingredients.count
    }
}

// MARK: - UIImagePickerControllerDelegate
extension RecipeEditViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let editedImage = info[.editedImage] as? UIImage
        let originalImage = info[.originalImage] as? UIImage
        let selectedImage = editedImage ?? originalImage
        
        if let image = selectedImage {
            imageData = image.jpegData(compressionQuality: 0.8)
            imageURL = nil
            tableView.reloadSections([Section.photo.rawValue], with: .automatic)
        }
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UITextViewDelegate
extension RecipeEditViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        recipeInstructions = textView.text
        if let cell = textView.superview?.superview as? RecipeEditInstructionsCell {
            cell.updatePlaceholder()
        }
        
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
}

// MARK: - TextField Handler
extension RecipeEditViewController {
    @objc private func nameTextFieldDidChange(_ textField: UITextField) {
        recipeName = textField.text ?? ""
    }
}

// MARK: - UnsplashImageSearchViewControllerDelegate
extension RecipeEditViewController: UnsplashImageSearchViewControllerDelegate {
    func didSelectImage(image: UIImage, imageURL: String) {
        self.imageData = image.jpegData(compressionQuality: 0.8)
        self.imageURL = imageURL
        tableView.reloadSections([Section.photo.rawValue], with: .automatic)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension RecipeEditViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return availableTags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCell", for: indexPath) as! TagCollectionViewCell
        let tag = availableTags[indexPath.item]
        cell.configure(with: tag, isSelected: selectedTags.contains(tag))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tag = availableTags[indexPath.item]
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
        collectionView.reloadItems(at: [indexPath])
    }
    
    @objc private func handleLongPressOnTag(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        _ = gesture.location(in: tableView)
        guard let tagsCell = tableView.cellForRow(at: IndexPath(row: 0, section: Section.tags.rawValue)) as? RecipeEditTagsCell else { return }
        
        let collectionPoint = gesture.location(in: tagsCell.collectionView)
        guard let indexPath = tagsCell.collectionView.indexPathForItem(at: collectionPoint) else { return }
        
        let tag = availableTags[indexPath.item]
        
        // Проверяем, является ли тег стандартным (стандартные теги нельзя удалить)
        let isDefaultTag = TagsManager.shared.defaultTags.contains(tag)
        
        // Создаём меню действий (action sheet)
        let alert = UIAlertController(title: "Tag: \(tag)", message: nil, preferredStyle: .actionSheet)
        
        // ИСПРАВЛЕНИЕ: Добавляем возможность редактирования тега
        // Можно редактировать только пользовательские теги (не стандартные)
        if !isDefaultTag {
            alert.addAction(UIAlertAction(title: "Edit", style: .default) { [weak self] _ in
                self?.editTag(tag)
            })
        }
        
        // Добавляем действие удаления
        // Стандартные теги можно только скрыть из текущего рецепта, но не удалить глобально
        if isDefaultTag {
            // Для стандартных тегов - только убрать из текущего рецепта
            alert.addAction(UIAlertAction(title: "Remove from Recipe", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                // Убираем тег только из текущего рецепта
                self.selectedTags.remove(tag)
                self.tableView.reloadSections([Section.tags.rawValue], with: .automatic)
            })
        } else {
            // Для пользовательских тегов - удалить глобально
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                // ИСПРАВЛЕНИЕ: Удаляем тег глобально через TagsManager
                // Теперь тег удалится из всех рецептов
                TagsManager.shared.deleteCustomTag(tag)
                // Убираем из выбранных тегов текущего рецепта
                self.selectedTags.remove(tag)
                // Перезагружаем секцию тегов
                self.tableView.reloadSections([Section.tags.rawValue], with: .automatic)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Для iPad нужно указать источник для popover
        if let popover = alert.popoverPresentationController {
            let cell = tagsCell.collectionView.cellForItem(at: indexPath)
            popover.sourceView = cell
            popover.sourceRect = cell?.bounds ?? .zero
        }
        
        present(alert, animated: true)
    }
    
    // РЕДАКТИРОВАНИЕ ТЕГА
    // Позволяет изменить название тега (старое название заменится на новое во всех рецептах)
    // ИСПРАВЛЕНИЕ: Добавлена возможность редактирования тегов
    private func editTag(_ oldTag: String) {
        let alert = UIAlertController(title: "Edit Tag", message: "Enter new tag name", preferredStyle: .alert)
        
        // Добавляем текстовое поле с текущим названием тега
        alert.addTextField { textField in
            textField.placeholder = "Tag name"
            textField.text = oldTag
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let textField = alert.textFields?.first,
                  let newName = textField.text?.trimmingCharacters(in: .whitespaces),
                  !newName.isEmpty,
                  newName != oldTag else {
                return
            }
            
            // Проверяем, не существует ли уже тег с таким названием
            let tagExists = self.availableTags.contains(where: { $0.lowercased() == newName.lowercased() && $0 != oldTag })
            
            if !tagExists {
                // Переименовываем тег глобально через TagsManager
                // Старое название заменится на новое во всех рецептах
                TagsManager.shared.renameTag(oldName: oldTag, newName: newName)
                
                // Обновляем выбранные теги текущего рецепта
                if self.selectedTags.contains(oldTag) {
                    self.selectedTags.remove(oldTag)
                    self.selectedTags.insert(newName)
                }
                
                // Перезагружаем секцию тегов
                self.tableView.reloadSections([Section.tags.rawValue], with: .automatic)
            } else {
                // Показываем ошибку, если тег с таким названием уже существует
                let errorAlert = UIAlertController(title: "Error", message: "Tag \"\(newName)\" already exists", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(errorAlert, animated: true)
            }
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension RecipeEditViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let tag = availableTags[indexPath.item]
        let font = UIFont.systemFont(ofSize: 14)
        let attributes = [NSAttributedString.Key.font: font]
        let size = (tag as NSString).size(withAttributes: attributes)
        // Добавляем padding: 12 слева + 12 справа = 24, плюс небольшой запас
        let width = size.width + 24 + 10
        return CGSize(width: width, height: 32)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 6
    }
}

// MARK: - Difficulty Change Handler
extension RecipeEditViewController {
    @objc private func difficultyDidChange(_ segmentedControl: UISegmentedControl) {
        difficultyValue = segmentedControl.selectedSegmentIndex
    }
}

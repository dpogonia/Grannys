//
//  RecipeEditViewController.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

class RecipeEditViewController: UIViewController {

    weak var delegate: RecipeEditViewControllerDelegate?

    private var recipe: Recipe?

    private var ingredients: [Ingredient] = []
    private var sources: [String] = []

    private var selectedCategories: Set<UUID> = []
    private var allCategories: [Category] = []

    private var isPhotoExpanded = false
    private var isIngredientsExpanded = true
    private var isSourcesExpanded = false
    private var isInstructionsExpanded = true
    private var isCategoriesExpanded = false
    private var isTagsExpanded = false
    private var isAdditionalExpanded = false

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()

    private var selectedTags: Set<String> = []
    
    private var availableTags: [String] {
        return TagsManager.shared.getAllAvailableTags()
    }
    
    private var initialCustomTags: [String] = []
    private var initialDeletedTags: Set<String> = []
    private var didSaveChanges = false
    private var renamedTagsDuringSession: [(oldName: String, newName: String)] = []

    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Delete", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 10
        return button
    }()

    private var imageData: Data?
    private var imageURL: String?
    private var difficultyValue: Int = UISegmentedControl.noSegment
    private var recipeName: String = ""
    private var recipeInstructions: String = ""
    private var cookingTime: Int?
    private var servings: Int?
    private var calories: Int?
    
    private let difficultyOptions = ["Easy", "Medium", "Hard"]
    private let difficultyPicker = UIPickerView()
    private let difficultyPickerTextField = UITextField(frame: .zero)

    private enum Section: Int, CaseIterable {
        case basicInfo = 0      // Recipe title
        case instructions = 1
        case ingredients = 2
        case photo = 3
        case extra = 4
        case sources = 5
        case categories = 6
        case tags = 7
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
        
        initialCustomTags = TagsManager.shared.getCustomTags()
        initialDeletedTags = TagsManager.shared.getDeletedTags()
        
        setupTableView()
        setupDeleteButton()
        setupView()
        setupNavigationBar()
        loadCategories()
        loadRecipeData()
        setupLayout()
        setupKeyboardDismissal()
        setupDifficultyPicker()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent && !didSaveChanges {
            for change in renamedTagsDuringSession {
                TagsManager.shared.renameTag(oldName: change.newName, newName: change.oldName)
            }
            TagsManager.shared.restoreState(customTags: initialCustomTags, deletedTags: initialDeletedTags)
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(RecipeEditNameCell.self, forCellReuseIdentifier: RecipeEditNameCell.identifier)
        tableView.register(RecipeEditInstructionsCell.self, forCellReuseIdentifier: RecipeEditInstructionsCell.identifier)
        tableView.register(RecipeEditPhotoCell.self, forCellReuseIdentifier: RecipeEditPhotoCell.identifier)
        tableView.register(RecipeEditDifficultyCell.self, forCellReuseIdentifier: RecipeEditDifficultyCell.identifier)
        tableView.register(RecipeEditNumericCell.self, forCellReuseIdentifier: RecipeEditNumericCell.identifier)
        tableView.register(RecipeEditStepperCell.self, forCellReuseIdentifier: RecipeEditStepperCell.identifier)
        tableView.register(RecipeEditTagsCell.self, forCellReuseIdentifier: RecipeEditTagsCell.identifier)
        tableView.register(RecipeEditIngredientInputCell.self, forCellReuseIdentifier: RecipeEditIngredientInputCell.identifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.tintColor = .grannyPink
    }
    
    private func setupDeleteButton() {
        deleteButton.addTarget(self, action: #selector(didTapDeleteButton), for: .touchUpInside)
    }

    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
    }

    private func setupDifficultyPicker() {
        difficultyPicker.dataSource = self
        difficultyPicker.delegate = self
        
        if difficultyValue != UISegmentedControl.noSegment,
           difficultyValue >= 0,
           difficultyValue < difficultyOptions.count {
            difficultyPicker.selectRow(difficultyValue, inComponent: 0, animated: false)
        }
        
        difficultyPickerTextField.inputView = difficultyPicker
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let cancelItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelDifficultySelection))
        let flexItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(applyDifficultySelection))
        toolbar.items = [cancelItem, flexItem, doneItem]
        difficultyPickerTextField.inputAccessoryView = toolbar
        
        difficultyPickerTextField.translatesAutoresizingMaskIntoConstraints = false
        difficultyPickerTextField.isHidden = true
        view.addSubview(difficultyPickerTextField)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if recipe != nil && tableView.tableFooterView == nil {
            setupDeleteButtonFooter()
        }

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
        saveButton.tintColor = .grannyPink
        navigationItem.rightBarButtonItem = saveButton
    }

    private func loadCategories() {
        allCategories = RecipesRepository.shared.getAllCategories()
    }

    private func loadRecipeData() {
        if let recipe = recipe {
            recipeName = recipe.name
            recipeInstructions = recipe.recipeInstructions ?? ""
            ingredients = recipe.ingredients
            sources = recipe.sources
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

            cookingTime = recipe.cookingTime
            servings = recipe.servings
            calories = recipe.calories

            selectedTags = Set(recipe.tags)

            for tag in recipe.tags where !TagsManager.shared.defaultTags.contains(tag) {
                TagsManager.shared.addCustomTag(tag)
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

        footerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width > 0 ? tableView.bounds.width : view.bounds.width, height: 82)
        tableView.tableFooterView = footerView
    }

    @objc private func didTapSave() {
        collectFormData()
        
        guard validateRecipeName() else {
            return
        }
        
        let recipeToSave = createRecipeToSave()
        saveRecipe(recipeToSave)
        didSaveChanges = true
        navigateBack()
    }
    
    private func collectFormData() {
        collectBasicInfo()
        collectExtraInfo()
        
        // Удаляем пустые ингредиенты перед сохранением
        ingredients = ingredients.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    private func collectBasicInfo() {
        if let nameCell = tableView.cellForRow(at: IndexPath(row: 0, section: Section.basicInfo.rawValue)) as? RecipeEditNameCell {
            recipeName = nameCell.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        }
        
        if let instructionsCell = tableView.cellForRow(at: IndexPath(row: 0, section: Section.instructions.rawValue)) as? RecipeEditInstructionsCell {
            recipeInstructions = instructionsCell.textView.text.trimmingCharacters(in: .whitespaces)
        }
    }
    
    private func collectExtraInfo() {
        // Values are updated live from stepper and numeric cells via onValueChanged / editingChanged handlers.
    }
    
    private func validateRecipeName() -> Bool {
        guard !recipeName.isEmpty else {
            showAlert(title: "Error", message: "Enter recipe name")
            return false
        }
        return true
    }
    
    private func createRecipeToSave() -> Recipe {
        let categories = allCategories.filter { selectedCategories.contains($0.id) }
        let difficulty = convertDifficultyToString()
        let tags = Array(selectedTags)
        
        if let existingRecipe = recipe {
            return createUpdatedRecipe(from: existingRecipe, categories: categories, difficulty: difficulty, tags: tags)
        } else {
            return createNewRecipe(categories: categories, difficulty: difficulty, tags: tags)
        }
    }
    
    private func convertDifficultyToString() -> String? {
        switch difficultyValue {
        case 0: return "easy"
        case 1: return "medium"
        case 2: return "hard"
        default: return nil
        }
    }
    
    private func createUpdatedRecipe(from existingRecipe: Recipe, categories: [Category], difficulty: String?, tags: [String]) -> Recipe {
        return Recipe(
            id: existingRecipe.id,
            name: recipeName,
            recipeInstructions: recipeInstructions.isEmpty ? nil : recipeInstructions,
            imageData: imageData,
            imageURL: imageURL,
            ingredients: ingredients,
            categories: categories,
            isArchived: existingRecipe.isArchived,
            isFavorite: existingRecipe.isFavorite,
            createdAt: existingRecipe.createdAt,
            cookingTime: cookingTime,
            servings: servings,
            difficulty: difficulty,
            calories: calories,
            tags: tags,
            sources: sources
        )
    }
    
    private func createNewRecipe(categories: [Category], difficulty: String?, tags: [String]) -> Recipe {
        return Recipe(
            name: recipeName,
            recipeInstructions: recipeInstructions.isEmpty ? nil : recipeInstructions,
            imageData: imageData,
            imageURL: imageURL,
            ingredients: ingredients,
            categories: categories,
            cookingTime: cookingTime,
            servings: servings,
            difficulty: difficulty,
            calories: calories,
            tags: tags,
            sources: sources
        )
    }
    
    private func saveRecipe(_ recipe: Recipe) {
        RecipesRepository.shared.saveRecipe(recipe)
        delegate?.didSaveRecipe()
    }
    
    private func navigateBack() {
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
        let alert = createImageSourceAlert(showDeleteOption: showDeleteOption)
        // Для единообразия показываем диалог по центру экрана (стиль .alert),
        // поэтому привязка к sourceView больше не нужна.
        present(alert, animated: true)
    }
    
    private func createImageSourceAlert(showDeleteOption: Bool) -> UIAlertController {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        
        addCameraAction(to: alert)
        addPhotoLibraryAction(to: alert)
        addUnsplashSearchAction(to: alert)
        
        if showDeleteOption {
            addDeletePhotoAction(to: alert)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        return alert
    }
    
    private func addCameraAction(to alert: UIAlertController) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        alert.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .camera)
        })
    }
    
    private func addPhotoLibraryAction(to alert: UIAlertController) {
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        })
    }
    
    private func addUnsplashSearchAction(to alert: UIAlertController) {
        alert.addAction(UIAlertAction(title: "Search Unsplash", style: .default) { [weak self] _ in
            self?.presentUnsplashSearch()
        })
    }
    
    private func addDeletePhotoAction(to alert: UIAlertController) {
        alert.addAction(UIAlertAction(title: "Delete Photo", style: .destructive) { [weak self] _ in
            self?.deletePhoto()
        })
    }
    
    private func configurePopoverPresentation(alert: UIAlertController, sourceView: UIView?) {
        guard let popover = alert.popoverPresentationController else { return }
        
        if let sourceView = sourceView {
            let rectInView = sourceView.convert(sourceView.bounds, to: view)
            popover.sourceView = view
            popover.sourceRect = rectInView
        } else {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
    }

    private func deletePhoto() {
        imageData = nil
        imageURL = nil
        tableView.reloadSections([Section.photo.rawValue], with: .automatic)
    }

    private func presentUnsplashSearch() {
        if let nameCell = tableView.cellForRow(at: IndexPath(row: 0, section: Section.basicInfo.rawValue)) as? RecipeEditNameCell {
            recipeName = nameCell.textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        }
        let searchQuery = recipeName.isEmpty ? "food recipe" : recipeName
        let searchVC = UnsplashImageSearchViewController(searchQuery: searchQuery)
        searchVC.delegate = self
        navigationController?.pushViewController(searchVC, animated: true)
    }

    @objc private func didTapAddIngredientButton() {
        let alert = UIAlertController(title: "New Ingredient", message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Ingredient name"
        }

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

            let amount = alert.textFields?[1].text?.trimmingCharacters(in: .whitespaces)
            let ingredient = Ingredient(name: name, amount: amount?.isEmpty == false ? amount : nil)
            self?.ingredients.append(ingredient)
            self?.tableView.reloadSections([Section.ingredients.rawValue], with: .automatic)
        })

        present(alert, animated: true)
    }

    private func editIngredient(at index: Int) {
        guard index < ingredients.count else { return }

        let ingredient = ingredients[index]

        let alert = UIAlertController(title: "Edit Ingredient", message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Ingredient name"
            textField.text = ingredient.name
        }

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

            let amount = alert.textFields?[1].text?.trimmingCharacters(in: .whitespaces)

            let updatedIngredient = Ingredient(
                id: ingredient.id,
                name: name,
                amount: amount?.isEmpty == false ? amount : nil
            )

            self.ingredients[index] = updatedIngredient

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

    @objc private func didTapAddTagButton() {
        let alert = UIAlertController(title: "New Tag", message: "Enter tag name", preferredStyle: .alert)

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

            let tagExists = self.availableTags.contains(where: { $0.lowercased() == name.lowercased() })

            if !tagExists {
                TagsManager.shared.addCustomTag(name)
            }

            self.selectedTags.insert(name)

            self.tableView.reloadSections([Section.tags.rawValue], with: .automatic)

            if let newTagIndex = self.availableTags.firstIndex(of: name) {
                if let tagsCell = self.tableView.cellForRow(at: IndexPath(row: 0, section: Section.tags.rawValue)) as? RecipeEditTagsCell {
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
    
    private func presentAddSourceAlert() {
        let alert = UIAlertController(title: "New Source", message: "Enter YouTube or other source URL", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "https://www.youtube.com/..."
            textField.keyboardType = .URL
            textField.autocapitalizationType = .none
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let text = alert.textFields?.first?.text?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty else {
                return
            }
            
            if !self.sources.contains(text) {
                self.sources.append(text)
                self.tableView.reloadSections([Section.sources.rawValue], with: .automatic)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func presentEditSourceAlert(at index: Int) {
        guard index < sources.count else { return }
        let current = sources[index]
        
        let alert = UIAlertController(title: "Edit Source", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "https://www.youtube.com/..."
            textField.text = current
            textField.keyboardType = .URL
            textField.autocapitalizationType = .none
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let text = alert.textFields?.first?.text?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty else {
                return
            }
            
            self.sources[index] = text
            self.tableView.reloadSections([Section.sources.rawValue], with: .automatic)
        })
        
        present(alert, animated: true)
    }
}

extension RecipeEditViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }

        switch sectionType {
        case .basicInfo:
            return 1
        case .ingredients:
            return isIngredientsExpanded ? ingredients.count + 1 : 0
        case .sources:
            return isSourcesExpanded ? sources.count + 1 : 0
        case .instructions:
            return isInstructionsExpanded ? 1 : 0
        case .photo:
            return isPhotoExpanded ? 1 : 0
        case .extra:
            return isAdditionalExpanded ? 4 : 0
        case .categories:
            return isCategoriesExpanded ? allCategories.count + 1 : 0
        case .tags:
            return isTagsExpanded ? 2 : 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionType = Section(rawValue: section) else { return nil }

        if sectionType == .basicInfo {
            return nil
        }

        let headerView = UIView()
        headerView.backgroundColor = .clear

        let titleLabel = UILabel()
        titleLabel.textColor = .secondaryLabel

        var isExpanded = false
        var showChevron = false

        switch sectionType {
        case .basicInfo:
            titleLabel.text = nil
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
        case .sources:
            titleLabel.text = "Sources"
            titleLabel.font = .systemFont(ofSize: 18, weight: .heavy)
            isExpanded = isSourcesExpanded
            showChevron = true
        case .instructions:
            titleLabel.text = "Cooking instructions"
            titleLabel.font = .systemFont(ofSize: 18, weight: .heavy)
            isExpanded = isInstructionsExpanded
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

        if showChevron {
            let chevronImageView = UIImageView()
            chevronImageView.translatesAutoresizingMaskIntoConstraints = false
            chevronImageView.tintColor = .grannyPink
            let systemName = isExpanded ? "chevron.down" : "chevron.right"
            chevronImageView.image = UIImage(systemName: systemName)
            chevronImageView.contentMode = .scaleAspectFit

            headerView.addSubview(titleLabel)
            headerView.addSubview(chevronImageView)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

                chevronImageView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
                chevronImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                chevronImageView.widthAnchor.constraint(equalToConstant: 10),
                chevronImageView.heightAnchor.constraint(equalToConstant: 16)
            ])

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapSectionHeader(_:)))
            headerView.addGestureRecognizer(tapGesture)
            headerView.tag = section
        } else {
            headerView.addSubview(titleLabel)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
            ])
        }

        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        return sectionType == .basicInfo ? 0.01 : 40
    }

    @objc private func didTapSectionHeader(_ gesture: UITapGestureRecognizer) {
        guard let headerView = gesture.view,
              let sectionType = Section(rawValue: headerView.tag) else { return }

        switch sectionType {
        case .photo:
            isPhotoExpanded.toggle()
        case .ingredients:
            isIngredientsExpanded.toggle()
        case .sources:
            isSourcesExpanded.toggle()
        case .instructions:
            isInstructionsExpanded.toggle()
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
            return cellForBasicInfoSection(at: indexPath, in: tableView)
        case .photo:
            return cellForPhotoSection(at: indexPath, in: tableView)
        case .ingredients:
            return cellForIngredientsSection(at: indexPath, in: tableView)
        case .sources:
            return cellForSourcesSection(at: indexPath, in: tableView)
        case .instructions:
            return cellForInstructionsSection(at: indexPath, in: tableView)
        case .extra:
            return cellForExtraSection(at: indexPath, in: tableView)
        case .categories:
            return cellForCategoriesSection(at: indexPath, in: tableView)
        case .tags:
            return cellForTagsSection(at: indexPath, in: tableView)
        }
    }

    private func cellForBasicInfoSection(at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecipeEditNameCell.identifier, for: indexPath) as! RecipeEditNameCell
        cell.textField.text = recipeName
        cell.textField.addTarget(self, action: #selector(nameTextFieldDidChange(_:)), for: .editingChanged)
        return cell
    }

    private func cellForInstructionsSection(at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecipeEditInstructionsCell.identifier, for: indexPath) as! RecipeEditInstructionsCell
        cell.textView.text = recipeInstructions
        cell.updatePlaceholder()
        cell.textView.delegate = self
        return cell
    }

    private func cellForPhotoSection(at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecipeEditPhotoCell.identifier, for: indexPath) as! RecipeEditPhotoCell
        cell.configure(hasImage: hasPhoto)

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

        if hasPhoto {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPhotoImageView(_:)))
            cell.photoImageView.addGestureRecognizer(tapGesture)
        } else {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapAddImageButton))
            cell.addPhotoImageView.addGestureRecognizer(tapGesture)
        }

        return cell
    }

    private func cellForIngredientsSection(at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        if indexPath.row < ingredients.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: RecipeEditIngredientInputCell.identifier, for: indexPath) as! RecipeEditIngredientInputCell
            let ingredient = ingredients[indexPath.row]
            cell.configure(name: ingredient.name, amount: ingredient.amount)
            cell.selectionStyle = .none
            cell.accessoryType = .none
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = "+ Add Ingredient"
            cell.textLabel?.textColor = .grannyPink
            cell.textLabel?.font = .systemFont(ofSize: 17)
            cell.selectionStyle = .default
            cell.accessoryType = .none
            return cell
        }
    }

    private func cellForSourcesSection(at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if indexPath.row < sources.count {
            let source = sources[indexPath.row]
            cell.textLabel?.text = source
            cell.textLabel?.textColor = .link
            cell.textLabel?.font = .systemFont(ofSize: 15)
            cell.selectionStyle = .default
            cell.accessoryType = .none
        } else {
            cell.textLabel?.text = "+ Add Source"
            cell.textLabel?.textColor = .grannyPink
            cell.textLabel?.font = .systemFont(ofSize: 17)
            cell.selectionStyle = .default
            cell.accessoryType = .none
        }
        return cell
    }

    private func cellForExtraSection(at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: RecipeEditStepperCell.identifier, for: indexPath) as! RecipeEditStepperCell
            cell.configure(title: "Cooking time", value: cookingTime, unit: "min", step: 5, minValue: 0, maxValue: 600)
            cell.onValueChanged = { [weak self] newValue in
                self?.cookingTime = newValue == 0 ? nil : newValue
            }
            return cell
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: RecipeEditStepperCell.identifier, for: indexPath) as! RecipeEditStepperCell
            cell.configure(title: "Servings", value: servings, unit: nil, step: 1, minValue: 0, maxValue: 50)
            cell.onValueChanged = { [weak self] newValue in
                self?.servings = newValue == 0 ? nil : newValue
            }
            return cell
        } else if indexPath.row == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: RecipeEditStepperCell.identifier, for: indexPath) as! RecipeEditStepperCell
            cell.configure(title: "Calories", value: calories, unit: "kcal", step: 5, minValue: 0, maxValue: 5000)
            cell.onValueChanged = { [weak self] newValue in
                self?.calories = newValue == 0 ? nil : newValue
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: RecipeEditDifficultyCell.identifier, for: indexPath) as! RecipeEditDifficultyCell
            cell.configure(selectedIndex: difficultyValue)
            return cell
        }
    }

    private func cellForCategoriesSection(at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
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
            cell.textLabel?.textColor = .grannyPink
            cell.textLabel?.font = .systemFont(ofSize: 17)
            cell.accessoryType = .none
            cell.selectionStyle = .default
        }
        return cell
    }

    private func cellForTagsSection(at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: RecipeEditTagsCell.identifier, for: indexPath) as! RecipeEditTagsCell
            cell.collectionView.dataSource = self
            cell.collectionView.delegate = self
            if let flowLayout = cell.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                flowLayout.minimumInteritemSpacing = 4
                flowLayout.minimumLineSpacing = 6
            }

            cell.collectionView.gestureRecognizers?.forEach { gesture in
                if gesture is UILongPressGestureRecognizer {
                    cell.collectionView.removeGestureRecognizer(gesture)
                }
            }

            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressOnTag(_:)))
            longPressGesture.minimumPressDuration = 0.5
            cell.collectionView.addGestureRecognizer(longPressGesture)

            cell.collectionView.reloadData()
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = "+ Add Tag"
            cell.textLabel?.textColor = .grannyPink
            cell.textLabel?.font = .systemFont(ofSize: 17)
            cell.accessoryType = .none
            cell.selectionStyle = .default
            return cell
        }
    }
}

extension RecipeEditViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Haptics.selection()
        tableView.deselectRow(at: indexPath, animated: true)

        guard let sectionType = Section(rawValue: indexPath.section) else { return }

        switch sectionType {
        case .ingredients:
            if indexPath.row == ingredients.count {
                ingredients.append(Ingredient(name: "", amount: nil))
                tableView.reloadSections([Section.ingredients.rawValue], with: .automatic)
            }
        case .sources:
            if indexPath.row == sources.count {
                presentAddSourceAlert()
            } else if indexPath.row < sources.count {
                presentEditSourceAlert(at: indexPath.row)
            }
        case .extra:
            if indexPath.row == 3 {
                difficultyPickerTextField.becomeFirstResponder()
            }
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
              editingStyle == .delete else {
            return
        }
        
        switch sectionType {
        case .ingredients where indexPath.row < ingredients.count:
            ingredients.remove(at: indexPath.row)
            tableView.reloadSections([Section.ingredients.rawValue], with: .automatic)
        case .sources where indexPath.row < sources.count:
            sources.remove(at: indexPath.row)
            tableView.reloadSections([Section.sources.rawValue], with: .automatic)
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let sectionType = Section(rawValue: indexPath.section) else { return false }
        switch sectionType {
        case .ingredients:
            return indexPath.row < ingredients.count
        case .sources:
            return indexPath.row < sources.count
        default:
            return false
        }
    }
}

extension RecipeEditViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
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

extension RecipeEditViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        recipeInstructions = textView.text
        if let cell = textView.superview?.superview?.superview as? RecipeEditInstructionsCell {
            cell.updatePlaceholder()
        }

        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
}

extension RecipeEditViewController {
    @objc private func nameTextFieldDidChange(_ textField: UITextField) {
        recipeName = textField.text ?? ""
    }

    @objc private func numericFieldDidChange(_ textField: UITextField) {
        let value = Int(textField.text ?? "")
        switch textField.tag {
        case 100:
            cookingTime = value
        case 101:
            servings = value
        case 102:
            calories = value
        default:
            break
        }
    }
}

extension RecipeEditViewController: UnsplashImageSearchViewControllerDelegate {
    func didSelectImage(image: UIImage, imageURL: String) {
        self.imageData = image.jpegData(compressionQuality: 0.8)
        self.imageURL = imageURL
        tableView.reloadSections([Section.photo.rawValue], with: .automatic)
    }
}

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
        Haptics.selection()
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
        guard let (tag, indexPath, tagsCell) = getTagFromGesture(gesture) else { return }
        
        let alert = createTagActionAlert(for: tag, tagsCell: tagsCell, indexPath: indexPath)
        present(alert, animated: true)
    }
    
    private func getTagFromGesture(_ gesture: UILongPressGestureRecognizer) -> (String, IndexPath, RecipeEditTagsCell)? {
        guard let tagsCell = tableView.cellForRow(at: IndexPath(row: 0, section: Section.tags.rawValue)) as? RecipeEditTagsCell else {
            return nil
        }
        
        let collectionPoint = gesture.location(in: tagsCell.collectionView)
        guard let indexPath = tagsCell.collectionView.indexPathForItem(at: collectionPoint) else {
            return nil
        }
        
        let tag = availableTags[indexPath.item]
        return (tag, indexPath, tagsCell)
    }
    
    private func createTagActionAlert(for tag: String, tagsCell: RecipeEditTagsCell, indexPath: IndexPath) -> UIAlertController {
        let alert = UIAlertController(title: "Tag: \(tag)", message: nil, preferredStyle: .actionSheet)
        
        addTagEditAction(to: alert, tag: tag)
        addTagDeleteAction(to: alert, tag: tag)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        configureTagAlertPopover(alert: alert, tagsCell: tagsCell, indexPath: indexPath)
        return alert
    }
    
    private func addTagEditAction(to alert: UIAlertController, tag: String) {
        alert.addAction(UIAlertAction(title: "Edit", style: .default) { [weak self] _ in
            self?.editTag(tag)
        })
    }
    
    private func addTagDeleteAction(to alert: UIAlertController, tag: String) {
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteTag(tag)
        })
    }
    
    private func removeTagFromRecipe(_ tag: String) {
        selectedTags.remove(tag)
        tableView.reloadSections([Section.tags.rawValue], with: .automatic)
    }
    
    private func deleteTag(_ tag: String) {
        TagsManager.shared.deleteCustomTag(tag)
        selectedTags.remove(tag)
        tableView.reloadSections([Section.tags.rawValue], with: .automatic)
    }
    
    private func configureTagAlertPopover(alert: UIAlertController, tagsCell: RecipeEditTagsCell, indexPath: IndexPath) {
        guard let popover = alert.popoverPresentationController else { return }
        let cell = tagsCell.collectionView.cellForItem(at: indexPath)
        popover.sourceView = cell
        popover.sourceRect = cell?.bounds ?? .zero
    }

    private func editTag(_ oldTag: String) {
        let alert = createEditTagAlert(for: oldTag)
        present(alert, animated: true)
    }
    
    private func createEditTagAlert(for oldTag: String) -> UIAlertController {
        let alert = UIAlertController(title: "Edit Tag", message: "Enter new tag name", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Tag name"
            textField.text = oldTag
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            self?.handleTagRename(from: alert, oldTag: oldTag)
        })
        
        return alert
    }
    
    private func handleTagRename(from alert: UIAlertController, oldTag: String) {
        guard let textField = alert.textFields?.first,
              let newName = textField.text?.trimmingCharacters(in: .whitespaces),
              !newName.isEmpty,
              newName != oldTag else {
            return
        }
        
        guard !isTagNameExists(newName, excluding: oldTag) else {
            showTagExistsError(for: newName)
            return
        }
        
        renameTag(from: oldTag, to: newName)
    }
    
    private func isTagNameExists(_ name: String, excluding excludedTag: String) -> Bool {
        return availableTags.contains(where: { $0.lowercased() == name.lowercased() && $0 != excludedTag })
    }
    
    private func showTagExistsError(for tagName: String) {
        let errorAlert = UIAlertController(title: "Error", message: "Tag \"\(tagName)\" already exists", preferredStyle: .alert)
        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
        present(errorAlert, animated: true)
    }
    
    private func renameTag(from oldTag: String, to newName: String) {
        renamedTagsDuringSession.append((oldName: oldTag, newName: newName))
        TagsManager.shared.renameTag(oldName: oldTag, newName: newName)
        
        if selectedTags.contains(oldTag) {
            selectedTags.remove(oldTag)
            selectedTags.insert(newName)
        }
        
        tableView.reloadSections([Section.tags.rawValue], with: .automatic)
    }
}

extension RecipeEditViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let tag = availableTags[indexPath.item]
        let font = UIFont.systemFont(ofSize: 14)
        let attributes = [NSAttributedString.Key.font: font]
        let size = (tag as NSString).size(withAttributes: attributes)
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

extension RecipeEditViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return difficultyOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return difficultyOptions[row]
    }
    
    @objc private func cancelDifficultySelection() {
        difficultyPickerTextField.resignFirstResponder()
    }
    
    @objc private func applyDifficultySelection() {
        let selectedRow = difficultyPicker.selectedRow(inComponent: 0)
        difficultyValue = selectedRow
        tableView.reloadRows(at: [IndexPath(row: 3, section: Section.extra.rawValue)], with: .none)
        difficultyPickerTextField.resignFirstResponder()
    }
}

extension RecipeEditViewController: RecipeEditIngredientInputCellDelegate {
    func ingredientInputCellDidChange(_ cell: RecipeEditIngredientInputCell, name: String, amount: String?) {
        guard let indexPath = tableView.indexPath(for: cell),
              indexPath.section == Section.ingredients.rawValue,
              indexPath.row < ingredients.count else { return }

        var existing = ingredients[indexPath.row]
        existing = Ingredient(id: existing.id, name: name, amount: amount)
        ingredients[indexPath.row] = existing
    }
}

//
//  RecipesViewController.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

class RecipesViewController: UIViewController {
    
    weak var coordinator: RecipesCoordinating?
    
    private var recipes: [Recipe] = []
    
    private var allCategories: [Category] = []
    
    private var selectedCategory: Category?
    
    private var isSearching = false
    
    private var filterTags: Set<String> = []
    
    private var filterDifficulty: String?
    
    private var filterIngredients: Set<String> = []
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        return control
    }()
    
    private let searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.placeholder = "Search recipes..."
        return controller
    }()
    
    private let categoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .label
        button.setTitleColor(.label, for: .normal)
        button.contentHorizontalAlignment = .left
        return button
    }()
    
    private let addButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    }()
    
    private let filterButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(systemName: "gearshape"), style: .plain, target: nil, action: nil)
    }()
    
    private let mealDBButton: UIBarButtonItem = {
        // Используем кастрюлю/сковороду как иконку для DBMeal
        return UIBarButtonItem(image: UIImage(systemName: "frying.pan"), style: .plain, target: nil, action: nil)
    }()
    
    private var emptyStateView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupEmptyStateView()
        setupView()
        setupTableView()
        setupNavigationBar()
        setupButtons()
        loadCategories()
        loadRecipes()
        setupConstraints()
    }
    
    private func setupEmptyStateView() {
        emptyStateView = EmptyStateViewFactory.createEmptyStateView(
            target: self,
            action: #selector(didTapAddButton)
        )
    }
    
    private func setupButtons() {
        refreshControl.addTarget(self, action: #selector(refreshRecipes), for: .valueChanged)
        categoryButton.addTarget(self, action: #selector(didTapCategoryButton), for: .touchUpInside)
        addButton.target = self
        addButton.action = #selector(didTapAddButton)
        filterButton.target = self
        filterButton.action = #selector(didTapFilterButton)
        mealDBButton.target = self
        mealDBButton.action = #selector(didTapMealDBButton)
    }

    // Публичный метод для обновления списка рецептов
    func reloadRecipes() {
        loadCategories()
        loadRecipes()
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRecipes()
        
        // Выравниваем стиль навбара с TheMealDBViewController
        let backgroundColor: UIColor = .systemBackground
        view.backgroundColor = backgroundColor
        
        if let navController = navigationController {
            navController.view.backgroundColor = backgroundColor
            
            if #available(iOS 15.0, *) {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = backgroundColor
                appearance.shadowColor = .clear
                
                navController.navigationBar.standardAppearance = appearance
                navController.navigationBar.scrollEdgeAppearance = appearance
                navController.navigationBar.compactAppearance = appearance
            } else {
                navController.navigationBar.isTranslucent = false
                navController.navigationBar.barTintColor = backgroundColor
                navController.navigationBar.shadowImage = UIImage()
                navController.navigationBar.setBackgroundImage(UIImage(), for: .default)
            }
        }
    }
    
    private let transitionDelegate = TransitionDelegate()
    
    @objc private func didTapCategoryButton() {
        coordinator?.showCategories(selectedCategory: selectedCategory)
    }
    
    @objc private func didTapAddButton() {
        coordinator?.showCreateRecipe()
    }
    
    @objc private func didTapFilterButton() {
        coordinator?.showFilters(selectedTags: filterTags, selectedDifficulty: filterDifficulty)
    }
    
    @objc private func didTapMealDBButton() {
        coordinator?.showMealDB()
    }
    
    @objc private func refreshRecipes() {
        loadRecipes()
        refreshControl.endRefreshing()
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

private extension RecipesViewController {
    
    func setupView() {
        view.backgroundColor = .systemBackground
    }
    
    
    func loadCategories() {
        allCategories = RecipesRepository.shared.getAllCategories()
    }

    func loadRecipes() {
        let loadedRecipes = fetchRecipesBasedOnSelection()
        recipes = applyFilters(to: loadedRecipes)
        updateCategoryButtonTitle()
        updateEmptyState()
        tableView.reloadData()
    }
    
    private func fetchRecipesBasedOnSelection() -> [Recipe] {
        let favoriteCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        let archiveCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")
        let isFavoriteSelected = selectedCategory?.id == favoriteCategoryId
        let isArchiveSelected = selectedCategory?.id == archiveCategoryId
        
        if isFavoriteSelected {
            return fetchFavoriteRecipes()
        } else if isArchiveSelected {
            return fetchArchivedRecipes()
        } else {
            return fetchRegularRecipes()
        }
    }
    
    private func fetchFavoriteRecipes() -> [Recipe] {
        if isSearching, let searchText = searchController.searchBar.text, !searchText.isEmpty {
            return filterRecipesBySearch(RecipesRepository.shared.getFavoriteRecipes(), searchText: searchText)
        } else {
            return RecipesRepository.shared.getFavoriteRecipes()
        }
    }
    
    private func fetchArchivedRecipes() -> [Recipe] {
        if isSearching, let searchText = searchController.searchBar.text, !searchText.isEmpty {
            return filterRecipesBySearch(RecipesRepository.shared.getAllRecipes(archived: true), searchText: searchText)
        } else {
            return RecipesRepository.shared.getAllRecipes(archived: true)
        }
    }
    
    private func fetchRegularRecipes() -> [Recipe] {
        if isSearching, let searchText = searchController.searchBar.text, !searchText.isEmpty {
            return RecipesRepository.shared.searchRecipes(query: searchText, in: selectedCategory)
        } else {
            return RecipesRepository.shared.getRecipes(in: selectedCategory, archived: false)
        }
    }
    
    private func filterRecipesBySearch(_ recipes: [Recipe], searchText: String) -> [Recipe] {
        return recipes.filter { recipe in
            recipe.name.localizedCaseInsensitiveContains(searchText) ||
            (recipe.recipeInstructions?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    private func applyFilters(to recipes: [Recipe]) -> [Recipe] {
        var filtered = recipes
        
        if !filterTags.isEmpty {
            filtered = filtered.filter { recipe in
                !recipe.tags.filter { filterTags.contains($0) }.isEmpty
            }
        }
        
        if let difficulty = filterDifficulty {
            filtered = filtered.filter { recipe in
                recipe.difficulty?.lowercased() == difficulty.lowercased()
            }
        }
        
        // Фильтрация по ингредиентам (AND логика - все выбранные ингредиенты должны присутствовать)
        if !filterIngredients.isEmpty {
            filtered = filtered.filter { recipe in
                let recipeIngredients = recipe.ingredients.map { $0.name.lowercased() }
                // Проверяем, что ВСЕ выбранные ингредиенты присутствуют в рецепте
                return filterIngredients.allSatisfy { selectedIngredient in
                    recipeIngredients.contains { recipeIngredient in
                        recipeIngredient.contains(selectedIngredient.lowercased())
                    }
                }
            }
        }
        
        return filtered
    }
    
    func updateEmptyState() {
        let isEmpty = recipes.isEmpty
        let wasHidden = emptyStateView.isHidden
        
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        
        if isEmpty && wasHidden {
            emptyStateView.alpha = 0
            UIView.animate(withDuration: 0.3) {
                self.emptyStateView.alpha = 1
            }
            
            if let iconImageView = emptyStateView.viewWithTag(999) as? UIImageView {
                iconImageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: [], animations: {
                    iconImageView.transform = .identity
                    iconImageView.alpha = 1
                }) { _ in
                    self.startPulsingAnimation(for: iconImageView)
                }
            }
        } else if !isEmpty {
            emptyStateView.alpha = 0
            if let iconImageView = emptyStateView.viewWithTag(999) as? UIImageView {
                iconImageView.layer.removeAllAnimations()
            }
        }
    }
    
    func updateCategoryButtonTitle() {
        let (titleText, _) = getCategoryTitleAndIcon()
        // Показываем только текст без иконки
        categoryButton.setAttributedTitle(nil, for: .normal)
        categoryButton.setTitle(titleText, for: .normal)
        categoryButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        // Стандартный цвет заголовка в стиле Apple
        categoryButton.setTitleColor(.label, for: .normal)
        categoryButton.frame = CGRect(x: 0, y: 0, width: 250, height: 44)
    }
    
    private func getCategoryTitleAndIcon() -> (String, UIImage?) {
        let favoriteCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        let archiveCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")
        let isFavoriteSelected = selectedCategory?.id == favoriteCategoryId
        let isArchiveSelected = selectedCategory?.id == archiveCategoryId
        
        let titleText: String
        let iconImage: UIImage?
        
        if isFavoriteSelected {
            titleText = CategoryLocalization.localizedBaseCategoryName("Favorites").uppercased()
            iconImage = UIImage(systemName: "heart.fill")
        } else if isArchiveSelected {
            titleText = CategoryLocalization.localizedBaseCategoryName("Archive").uppercased()
            iconImage = UIImage(systemName: "archivebox.fill")
        } else if let category = selectedCategory {
            titleText = CategoryLocalization.localizedBaseCategoryName(category.name).uppercased()
            iconImage = UIImage(systemName: "fork.knife")
        } else {
            titleText = CategoryLocalization.localizedBaseCategoryName("All Recipes").uppercased()
            iconImage = UIImage(systemName: "fork.knife")
        }
        
        return (titleText, iconImage)
    }
    
    private func createAttributedTitle(text: String, icon: UIImage?) -> NSAttributedString {
        let font = UIFont.systemFont(ofSize: 19.5, weight: .regular)
        
        let iconAttachment = NSTextAttachment()
        iconAttachment.image = icon?.withTintColor(.label, renderingMode: .alwaysOriginal)
        iconAttachment.bounds = CGRect(x: 0, y: -1, width: 18.2, height: 18.2)
        
        let iconString = NSAttributedString(attachment: iconAttachment)
        let spacing = NSAttributedString(string: " ", attributes: [.font: font])
        let titleString = NSAttributedString(
            string: text,
            attributes: [.font: font, .foregroundColor: UIColor.label]
        )
        
        let attributedTitle = NSMutableAttributedString()
        attributedTitle.append(iconString)
        attributedTitle.append(spacing)
        attributedTitle.append(titleString)
        
        return attributedTitle
    }
    
    func setupTableView() {
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        tableView.register(
            RecipeTableViewCell.self,
            forCellReuseIdentifier: RecipeTableViewCell.cellIdentifier
        )
        tableView.refreshControl = refreshControl
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
    }
    
    func setupNavigationBar() {
        navigationItem.titleView = categoryButton
        // Порядок справа налево: +, Settings, DBMeal (chef icon)
        navigationItem.rightBarButtonItems = [addButton, filterButton, mealDBButton]
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchResultsUpdater = self
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func startPulsingAnimation(for imageView: UIImageView) {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        
        pulseAnimation.fromValue = 1.0
        
        pulseAnimation.toValue = 1.15
        
        pulseAnimation.duration = 1.0
        
        pulseAnimation.autoreverses = true
        
        pulseAnimation.repeatCount = .infinity
        
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        imageView.layer.add(pulseAnimation, forKey: "pulsing")
    }
}

extension RecipesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = recipes.count
        
        updateEmptyState()
        
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: RecipeTableViewCell.cellIdentifier,
            for: indexPath
        ) as? RecipeTableViewCell else {
            assertionFailure("Cell registration failed")
            return UITableViewCell()
        }
        
        let recipe = recipes[indexPath.row]
        
        cell.configure(with: recipe)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row < recipes.count && cell.alpha == 1.0 {
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: 20)
            
            UIView.animate(withDuration: 0.3, delay: Double(indexPath.row % 10) * 0.05, options: .curveEaseOut, animations: {
                cell.alpha = 1
                cell.transform = .identity
            })
        }
    }
}

extension RecipesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Haptics.lightImpact()
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedRecipe = recipes[indexPath.row]
        
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.alpha = 0.5
            UIView.animate(withDuration: 0.2) {
                cell.alpha = 1.0
            }
        }
        coordinator?.showRecipeDetail(recipe: selectedRecipe)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let recipe = recipes[indexPath.row]
            RecipesRepository.shared.archiveRecipe(recipe)
            recipes.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            updateEmptyState()
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let recipe = recipes[indexPath.row]
        let isFavorite = recipe.isFavorite
        
        let favoriteAction = UIContextualAction(style: .normal, title: nil) { [weak self] (action, view, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
            }
            
            let favoriteCommand = ToggleFavoriteCommand(recipe: recipe)
            CommandManager.shared.execute(command: favoriteCommand)
            
            if let updatedRecipe = RecipesRepository.shared.getRecipe(by: recipe.id) {
                let favoriteCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")
                let isFavoritesList = self.selectedCategory?.id == favoriteCategoryId
                
                if isFavoritesList && !updatedRecipe.isFavorite {
                    // Если находимся в списке избранного и рецепт снят с избранного,
                    // сразу удаляем его из таблицы
                    self.recipes.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                    self.updateEmptyState()
                } else {
                    // В остальных списках просто обновляем состояние ячейки
                    self.recipes[indexPath.row] = updatedRecipe
                    tableView.reloadRows(at: [indexPath], with: .none)
                }
                
                // Показываем Snackbar с возможностью отмены
                self.showSnackbar(message: favoriteCommand.description) { [weak self] in
                    guard let self = self else { return }
                    if let _ = CommandManager.shared.undo() {
                        self.reloadRecipes()
                    }
                }
            }
            
            completionHandler(true)
        }
        
        favoriteAction.image = UIImage(systemName: isFavorite ? "heart.slash.fill" : "heart.fill")
        favoriteAction.backgroundColor = isFavorite ? .systemGray : .grannyPink
        
        return UISwipeActionsConfiguration(actions: [favoriteAction])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let recipe = recipes[indexPath.row]
        let archiveCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")
        let isArchiveSelected = selectedCategory?.id == archiveCategoryId
        
        if isArchiveSelected {
            return createArchiveSwipeActions(for: recipe, at: indexPath, in: tableView)
        } else {
            return createRegularSwipeActions(for: recipe, at: indexPath, in: tableView)
        }
    }
    
    private func createArchiveSwipeActions(for recipe: Recipe, at indexPath: IndexPath, in tableView: UITableView) -> UISwipeActionsConfiguration {
        let unarchiveAction = createUnarchiveAction(for: recipe, at: indexPath, in: tableView)
        let deleteAction = createDeleteAction(for: recipe, at: indexPath, in: tableView)
        return UISwipeActionsConfiguration(actions: [deleteAction, unarchiveAction])
    }
    
    private func createRegularSwipeActions(for recipe: Recipe, at indexPath: IndexPath, in tableView: UITableView) -> UISwipeActionsConfiguration {
        let archiveAction = createArchiveAction(for: recipe, at: indexPath, in: tableView)
        let deleteAction = createDeleteAction(for: recipe, at: indexPath, in: tableView)
        return UISwipeActionsConfiguration(actions: [deleteAction, archiveAction])
    }
    
    private func createUnarchiveAction(for recipe: Recipe, at indexPath: IndexPath, in tableView: UITableView) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: nil) { [weak self] (_, _, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
            }
            
            let command = ArchiveRecipeCommand(recipe: recipe)
            CommandManager.shared.execute(command: command)
            
            self.removeRecipe(at: indexPath, in: tableView)
            
            self.showSnackbar(message: command.description) { [weak self] in
                guard let self = self else { return }
                if let _ = CommandManager.shared.undo() {
                    self.reloadRecipes()
                }
            }
            
            completionHandler(true)
        }
        action.image = UIImage(systemName: "tray.and.arrow.up.fill")
        action.backgroundColor = .systemGreen
        return action
    }
    
    private func createArchiveAction(for recipe: Recipe, at indexPath: IndexPath, in tableView: UITableView) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: nil) { [weak self] (_, _, completionHandler) in
            guard let self = self else {
                completionHandler(false)
                return
            }
            
            let command = ArchiveRecipeCommand(recipe: recipe)
            CommandManager.shared.execute(command: command)
            
            self.removeRecipe(at: indexPath, in: tableView)
            
            self.showSnackbar(message: command.description) { [weak self] in
                guard let self = self else { return }
                if let _ = CommandManager.shared.undo() {
                    self.reloadRecipes()
                }
            }
            
            completionHandler(true)
        }
        action.image = UIImage(systemName: "archivebox.fill")
        action.backgroundColor = .systemOrange
        return action
    }
    
    private func createDeleteAction(for recipe: Recipe, at indexPath: IndexPath, in tableView: UITableView) -> UIContextualAction {
        let action = UIContextualAction(style: .destructive, title: nil) { [weak self] (_, _, completionHandler) in
            self?.showDeleteConfirmation(for: recipe, at: indexPath, in: tableView, completionHandler: completionHandler)
        }
        action.image = UIImage(systemName: "trash.fill")
        return action
    }
    
    private func removeRecipe(at indexPath: IndexPath, in tableView: UITableView) {
        recipes.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
        updateEmptyState()
    }
    
    private func showDeleteConfirmation(for recipe: Recipe, at indexPath: IndexPath, in tableView: UITableView, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: "Delete recipe?",
            message: "This action cannot be undone",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(false)
        })
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            RecipesRepository.shared.deleteRecipe(recipe)
            self?.removeRecipe(at: indexPath, in: tableView)
            completionHandler(true)
        })
        
        present(alert, animated: true)
    }
}

extension RecipesViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        isSearching = !searchController.searchBar.text!.isEmpty
        loadRecipes()
    }
}

extension RecipesViewController: CategoriesViewControllerDelegate {
    func didSelectCategory(_ category: Category?) {
        selectedCategory = category
        loadRecipes()
    }
}

extension RecipesViewController: RecipeEditViewControllerDelegate {
    func didSaveRecipe() {
        // ПАТТЕРН OBSERVER: Реакция на уведомление о сохранении рецепта
        // Автоматически обновляем список рецептов
        loadRecipes()
    }
}

extension RecipesViewController: RecipeDetailViewControllerDelegate {
    func didUpdateRecipe() {
        loadRecipes()
    }
    
    func didDeleteRecipe() {
        loadRecipes()
    }
}


extension RecipesViewController: CategoriesSelectionViewControllerDelegate {
    func didAddRecipe() {
        loadRecipes()
    }
}

extension RecipesViewController: FilterViewControllerDelegate {
    func didApplyFilters(selectedTags: Set<String>, selectedDifficulty: String?, selectedIngredients: Set<String>) {
        filterTags = selectedTags
        filterDifficulty = selectedDifficulty
        filterIngredients = selectedIngredients
        loadRecipes()
    }
}


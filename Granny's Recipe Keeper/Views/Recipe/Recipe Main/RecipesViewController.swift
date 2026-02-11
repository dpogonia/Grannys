//
//  RecipesViewController.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

class RecipesViewController: UIViewController {
    
    private var recipes: [Recipe] = []
    
    private var allCategories: [Category] = []
    
    private var selectedCategory: Category?
    
    private var isSearching = false
    
    private var filterTags: Set<String> = []
    
    private var filterDifficulty: String?
    
    private var filterIngredients: Set<String> = []
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(
            RecipeTableViewCell.self,
            forCellReuseIdentifier: RecipeTableViewCell.cellIdentifier
        )
        tableView.refreshControl = refreshControl
        return tableView
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refreshRecipes), for: .valueChanged)
        return control
    }()
    
    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.placeholder = "Search recipes..."
        return controller
    }()
    
    private lazy var categoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .label
        button.setTitleColor(.label, for: .normal)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(didTapCategoryButton), for: .touchUpInside)
        return button
    }()
    
    private lazy var addButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(didTapAddButton)
        )
        return button
    }()
    
    private lazy var filterButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            style: .plain,
            target: self,
            action: #selector(didTapFilterButton)
        )
        return button
    }()
    
    private lazy var mealDBButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "globe"),
            style: .plain,
            target: self,
            action: #selector(didTapMealDBButton)
        )
        return button
    }()
    
    private lazy var emptyStateView: UIView = {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.isHidden = true
        
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(systemName: "fork.knife.circle.fill")
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tag = 999
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "No recipes"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        
        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.text = "Add your first recipe\nto start cooking!"
        messageLabel.font = .systemFont(ofSize: 17, weight: .regular)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        let addButton = UIButton(type: .system)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle("Add Recipe", for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        addButton.setTitleColor(.white, for: .normal)
        addButton.backgroundColor = .systemBlue
        addButton.layer.cornerRadius = 12
        addButton.layer.shadowColor = UIColor.systemBlue.cgColor
        addButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        addButton.layer.shadowRadius = 8
        addButton.layer.shadowOpacity = 0.3
        addButton.addTarget(self, action: #selector(didTapAddButton), for: .touchUpInside)
        
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 240),
            iconImageView.heightAnchor.constraint(equalToConstant: 240),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -32),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 32),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -32),
            
            addButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 32),
            addButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 200),
            addButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        iconImageView.alpha = 0
        titleLabel.alpha = 0
        messageLabel.alpha = 0
        addButton.alpha = 0
        
        return containerView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        loadCategories()
        loadRecipes()
        setupTableView()
        setupConstraints()
        setupNavigationBar()
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
    }
    
    private let transitionDelegate = TransitionDelegate()
    
    @objc private func didTapCategoryButton() {
        let categoriesVC = CategoriesViewController()
        categoriesVC.delegate = self
        categoriesVC.selectedCategory = selectedCategory
        navigationController?.pushViewController(categoriesVC, animated: true)
    }
    
    @objc private func didTapAddButton() {
        let editVC = RecipeEditViewController()
        editVC.delegate = self
        navigationController?.pushViewController(editVC, animated: true)
    }
    
    @objc private func didTapFilterButton() {
        let filterVC = FilterViewController(selectedTags: filterTags, selectedDifficulty: filterDifficulty)
        filterVC.delegate = self
        let navController = UINavigationController(rootViewController: filterVC)
        present(navController, animated: true)
    }
    
    @objc private func didTapMealDBButton() {
        let mealDBVC = TheMealDBViewController()
        let navController = UINavigationController(rootViewController: mealDBVC)
        
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
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
    
    func setupNavigationBar() {
        navigationItem.titleView = categoryButton
        navigationItem.rightBarButtonItems = [addButton, mealDBButton, filterButton]
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    func loadCategories() {
        allCategories = RecipesRepository.shared.getAllCategories()
    }

    func loadRecipes() {
        let favoriteCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        let archiveCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")
        let isFavoriteSelected = selectedCategory?.id == favoriteCategoryId
        let isArchiveSelected = selectedCategory?.id == archiveCategoryId
        
        var loadedRecipes: [Recipe] = []
        
        if isFavoriteSelected {
            if isSearching, let searchText = searchController.searchBar.text, !searchText.isEmpty {
                let favoriteRecipes = RecipesRepository.shared.getFavoriteRecipes()
                loadedRecipes = favoriteRecipes.filter { recipe in
                    recipe.name.localizedCaseInsensitiveContains(searchText) ||
                    (recipe.recipeInstructions?.localizedCaseInsensitiveContains(searchText) ?? false)
                }
            } else {
                loadedRecipes = RecipesRepository.shared.getFavoriteRecipes()
            }
        } else if isArchiveSelected {
            if isSearching, let searchText = searchController.searchBar.text, !searchText.isEmpty {
                let archivedRecipes = RecipesRepository.shared.getAllRecipes(archived: true)
                loadedRecipes = archivedRecipes.filter { recipe in
                    recipe.name.localizedCaseInsensitiveContains(searchText) ||
                    (recipe.recipeInstructions?.localizedCaseInsensitiveContains(searchText) ?? false)
                }
            } else {
                loadedRecipes = RecipesRepository.shared.getAllRecipes(archived: true)
            }
        } else {
            if isSearching, let searchText = searchController.searchBar.text, !searchText.isEmpty {
                loadedRecipes = RecipesRepository.shared.searchRecipes(query: searchText, in: selectedCategory)
            } else {
                loadedRecipes = RecipesRepository.shared.getRecipes(in: selectedCategory, archived: false)
            }
        }
        
        recipes = applyFilters(to: loadedRecipes)
        
        updateCategoryButtonTitle()
        updateEmptyState()
        tableView.reloadData()
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
        let titleText: String
        let favoriteCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        let archiveCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")
        let isFavoriteSelected = selectedCategory?.id == favoriteCategoryId
        let isArchiveSelected = selectedCategory?.id == archiveCategoryId
        
        if isFavoriteSelected {
            titleText = "FAVORITES"
        } else if isArchiveSelected {
            titleText = "ARCHIVE"
        } else if let category = selectedCategory {
            titleText = category.name.uppercased()
        } else {
            titleText = "ALL RECIPES"
        }
        
        let iconImage: UIImage?
        if isFavoriteSelected {
            iconImage = UIImage(systemName: "heart.fill")
        } else if isArchiveSelected {
            iconImage = UIImage(systemName: "archivebox.fill")
        } else {
            iconImage = UIImage(systemName: "fork.knife")
        }
        
        let font = UIFont.systemFont(ofSize: 19.5, weight: .regular)
        
        let iconAttachment = NSTextAttachment()
        iconAttachment.image = iconImage?.withTintColor(.label, renderingMode: .alwaysOriginal)
        
        let iconSize: CGFloat = 18.2
        iconAttachment.bounds = CGRect(x: 0, y: -1, width: iconSize, height: iconSize)
        
        let iconString = NSAttributedString(attachment: iconAttachment)
        let spacing = NSAttributedString(string: " ", attributes: [.font: font])
        
        let titleString = NSAttributedString(
            string: titleText,
            attributes: [
                .font: font,
                .foregroundColor: UIColor.label
            ]
        )
        
        let attributedTitle = NSMutableAttributedString()
        attributedTitle.append(iconString)
        attributedTitle.append(spacing)
        attributedTitle.append(titleString)
        
        categoryButton.setAttributedTitle(attributedTitle, for: .normal)
        
        let maxWidth: CGFloat = 250
        categoryButton.frame = CGRect(x: 0, y: 0, width: maxWidth, height: 44)
    }
    
    func setupTableView() {
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        tableView.dataSource = self
        tableView.delegate = self
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
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedRecipe = recipes[indexPath.row]
        
        let detailViewController = RecipeDetailViewController(recipe: selectedRecipe)
        
        detailViewController.delegate = self
        
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.alpha = 0.5
            UIView.animate(withDuration: 0.2) {
                cell.alpha = 1.0
            }
        }
        
        navigationController?.pushViewController(detailViewController, animated: true)
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
            RecipesRepository.shared.toggleFavorite(recipe)
            
            if let updatedRecipe = RecipesRepository.shared.getRecipe(by: recipe.id) {
                self?.recipes[indexPath.row] = updatedRecipe
                tableView.reloadRows(at: [indexPath], with: .none)
            }
            
            completionHandler(true)
        }
        
        favoriteAction.image = UIImage(systemName: isFavorite ? "heart.slash.fill" : "heart.fill")
        favoriteAction.backgroundColor = isFavorite ? .systemGray : .systemRed
        
        return UISwipeActionsConfiguration(actions: [favoriteAction])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let recipe = recipes[indexPath.row]
        let archiveCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")
        let isArchiveSelected = selectedCategory?.id == archiveCategoryId
        
        if isArchiveSelected {
            let unarchiveAction = UIContextualAction(style: .normal, title: nil) { [weak self] (action, view, completionHandler) in
                RecipesRepository.shared.unarchiveRecipe(recipe)
                self?.recipes.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                self?.updateEmptyState()
                completionHandler(true)
            }
            unarchiveAction.image = UIImage(systemName: "tray.and.arrow.up.fill")
            unarchiveAction.backgroundColor = .systemGreen
            
            let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] (action, view, completionHandler) in
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
                    self?.recipes.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    self?.updateEmptyState()
                    completionHandler(true)
                })
                
                self?.present(alert, animated: true)
            }
            deleteAction.image = UIImage(systemName: "trash.fill")
            
            return UISwipeActionsConfiguration(actions: [deleteAction, unarchiveAction])
        } else {
            let archiveAction = UIContextualAction(style: .normal, title: nil) { [weak self] (action, view, completionHandler) in
                RecipesRepository.shared.archiveRecipe(recipe)
                self?.recipes.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                self?.updateEmptyState()
                completionHandler(true)
            }
            archiveAction.image = UIImage(systemName: "archivebox.fill")
            archiveAction.backgroundColor = .systemOrange
            
            let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] (action, view, completionHandler) in
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
                    self?.recipes.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    self?.updateEmptyState()
                    completionHandler(true)
                })
                
                self?.present(alert, animated: true)
            }
            deleteAction.image = UIImage(systemName: "trash.fill")
            
            return UISwipeActionsConfiguration(actions: [deleteAction, archiveAction])
        }
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


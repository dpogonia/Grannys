//
//  TheMealDBViewController.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

class TheMealDBViewController: UIViewController {
    
    private var recipes: [TheMealDBRecipe] = []
    private var categories: [TheMealDBCategory] = []
    private var selectedCategory: String?
    private var isLoading = false
    private var isLoadingMore = false
    private var hasMoreRecipes = true
    private var currentOffset = 0
    private let pageSize = 10
    
    private lazy var categoriesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(
            CategoryCollectionViewCell.self,
            forCellWithReuseIdentifier: CategoryCollectionViewCell.cellIdentifier
        )
        return collectionView
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(
            RecipeTableViewCell.self,
            forCellReuseIdentifier: RecipeTableViewCell.cellIdentifier
        )
        tableView.register(
            SkeletonLoadingCell.self,
            forCellReuseIdentifier: SkeletonLoadingCell.cellIdentifier
        )
        tableView.refreshControl = refreshControl
        return tableView
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return control
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var randomButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "shuffle"),
            style: .plain,
            target: self,
            action: #selector(didTapRandomButton)
        )
        return button
    }()
    
    
    private lazy var searchButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            barButtonSystemItem: .search,
            target: self,
            action: #selector(didTapSearchButton)
        )
        return button
    }()
    
    private lazy var backButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(didTapBack)
        )
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationBar()
        setupTableView()
        setupConstraints()
        loadCategories()
        loadCachedRecipes()
        loadRandomRecipes()
    }
    
    private func loadCachedRecipes() {
        if let cachedRecipes = TheMealDBCache.shared.getCachedRecipes() {
            recipes = cachedRecipes
            tableView.reloadData()
        }
    }
    
    @objc private func didTapRandomButton() {
        loadRandomRecipe()
    }
    
    
    @objc private func didTapSearchButton() {
        showSearchAlert()
    }
    
    @objc private func didTapBack() {
        dismiss(animated: true)
    }
    
    @objc private func refreshData() {
        currentOffset = 0
        hasMoreRecipes = true
        if let category = selectedCategory {
            loadRecipesByCategory(category)
        } else {
            loadRandomRecipes()
        }
    }
    
    private func loadRandomRecipe() {
        guard !isLoading else { return }
        isLoading = true
        activityIndicator.startAnimating()
        
        TheMealDBService.shared.getRandomRecipe { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.activityIndicator.stopAnimating()
                self?.refreshControl.endRefreshing()
                
                switch result {
                case .success(let recipe):
                    self?.recipes = [recipe]
                    self?.selectedCategory = nil
                    self?.updateTitle()
                    self?.tableView.reloadData()
                    self?.animateCellsAppearance()
                case .failure(let error):
                    self?.showError(error)
                }
            }
        }
    }
    
    private func loadRandomRecipes(append: Bool = false) {
        guard !isLoading && !isLoadingMore else { return }
        
        if append {
            isLoadingMore = true
        } else {
            isLoading = true
            activityIndicator.startAnimating()
            currentOffset = 0
            hasMoreRecipes = true
        }
        
        let group = DispatchGroup()
        var loadedRecipes: [TheMealDBRecipe] = []
        var lastError: NetworkError?
        
        let count = append ? 5 : 10
        for _ in 0..<count {
            group.enter()
            TheMealDBService.shared.getRandomRecipe { result in
                switch result {
                case .success(let recipe):
                    loadedRecipes.append(recipe)
                case .failure(let error):
                    lastError = error
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            self.isLoading = false
            self.isLoadingMore = false
            self.activityIndicator.stopAnimating()
            self.refreshControl.endRefreshing()
            
            if loadedRecipes.isEmpty, let error = lastError {
                if !append {
                    self.showError(error)
                }
                self.hasMoreRecipes = false
            } else {
                if append {
                    self.recipes.append(contentsOf: loadedRecipes)
                    let startIndex = self.recipes.count - loadedRecipes.count
                    let indexPaths = (startIndex..<self.recipes.count).map { IndexPath(row: $0, section: 0) }
                    self.tableView.insertRows(at: indexPaths, with: .fade)
                } else {
                    self.recipes = loadedRecipes
                    self.selectedCategory = nil
                    self.updateTitle()
                    TheMealDBCache.shared.cacheRecipes(loadedRecipes)
                    self.tableView.reloadData()
                    self.animateCellsAppearance()
                }
            }
        }
    }
    
    private func loadRecipesByCategory(_ category: String, append: Bool = false) {
        guard !isLoading && !isLoadingMore else { return }
        
        if append {
            isLoadingMore = true
        } else {
            isLoading = true
            activityIndicator.startAnimating()
            currentOffset = 0
            hasMoreRecipes = true
        }
        
        let offset = append ? currentOffset : 0
        
        TheMealDBService.shared.getRecipesByCategory(category, offset: offset, limit: pageSize) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                self.isLoadingMore = false
                self.activityIndicator.stopAnimating()
                self.refreshControl.endRefreshing()
                
                switch result {
                case .success(let newRecipes):
                    if newRecipes.isEmpty {
                        self.hasMoreRecipes = false
                    } else {
                        if append {
                            self.recipes.append(contentsOf: newRecipes)
                            self.currentOffset += newRecipes.count
                            let startIndex = self.recipes.count - newRecipes.count
                            let indexPaths = (startIndex..<self.recipes.count).map { IndexPath(row: $0, section: 0) }
                            self.tableView.insertRows(at: indexPaths, with: .fade)
                            
                            if newRecipes.count < self.pageSize {
                                self.hasMoreRecipes = false
                            }
                        } else {
                            self.recipes = newRecipes
                            self.selectedCategory = category
                            self.currentOffset = newRecipes.count
                            self.updateTitle()
                            TheMealDBCache.shared.cacheRecipes(newRecipes)
                            self.tableView.reloadData()
                            self.animateCellsAppearance()
                            
                            if newRecipes.count < self.pageSize {
                                self.hasMoreRecipes = false
                            }
                        }
                    }
                case .failure(let error):
                    if !append {
                        self.showError(error)
                    }
                    self.hasMoreRecipes = false
                }
            }
        }
    }
    
    private func searchRecipes(_ query: String) {
        guard !isLoading else { return }
        isLoading = true
        activityIndicator.startAnimating()
        hasMoreRecipes = false
        
        TheMealDBService.shared.searchRecipesByName(query) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.activityIndicator.stopAnimating()
                self?.refreshControl.endRefreshing()
                
                switch result {
                case .success(let recipes):
                    self?.recipes = recipes
                    self?.selectedCategory = nil
                    self?.updateTitle()
                    TheMealDBCache.shared.cacheRecipes(recipes)
                    self?.tableView.reloadData()
                    self?.animateCellsAppearance()
                    
                    if recipes.isEmpty {
                        self?.showAlert(title: "No Results Found", message: "Try changing your search query")
                    }
                case .failure(let error):
                    self?.showError(error)
                }
            }
        }
    }
    
    private func loadCategories() {
        TheMealDBService.shared.getCategories { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let categories):
                    self?.categories = categories
                    self?.categoriesCollectionView.reloadData()
                case .failure:
                    break
                }
            }
        }
    }
    
    private func showSearchAlert() {
        let alert = UIAlertController(title: "Search Recipe", message: "Enter recipe name", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Recipe name"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Search", style: .default) { [weak self] _ in
            guard let query = alert.textFields?.first?.text, !query.isEmpty else { return }
            self?.searchRecipes(query)
        })
        
        present(alert, animated: true)
    }
    
    private func updateTitle() {
        navigationItem.titleView = nil
        navigationItem.title = nil
        
        if let category = selectedCategory {
            navigationItem.accessibilityLabel = "TheMealDB - \(category)"
        } else {
            navigationItem.accessibilityLabel = "TheMealDB Recipes"
        }
    }
    
    private func showError(_ error: NetworkError) {
        showAlert(title: "Error", message: error.localizedDescription)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        updateTitle()
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = backButton
        navigationItem.rightBarButtonItems = [randomButton, searchButton]
    }
    
    private func setupTableView() {
        view.addSubview(categoriesCollectionView)
        view.addSubview(tableView)
        categoriesCollectionView.dataSource = self
        categoriesCollectionView.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func setupConstraints() {
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            categoriesCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            categoriesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoriesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoriesCollectionView.heightAnchor.constraint(equalToConstant: 100),
            
            tableView.topAnchor.constraint(equalTo: categoriesCollectionView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func animateCellsAppearance() {
        let visibleCells = tableView.visibleCells
        for (index, cell) in visibleCells.enumerated() {
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: 20)
            UIView.animate(withDuration: 0.3, delay: Double(index) * 0.05, options: .curveEaseOut, animations: {
                cell.alpha = 1
                cell.transform = .identity
            })
        }
    }
}

extension TheMealDBViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading {
            return 5
        }
        return recipes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isLoading {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: SkeletonLoadingCell.cellIdentifier,
                for: indexPath
            ) as? SkeletonLoadingCell else {
                assertionFailure("Skeleton cell registration failed")
                return UITableViewCell()
            }
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: RecipeTableViewCell.cellIdentifier,
            for: indexPath
        ) as? RecipeTableViewCell else {
            assertionFailure("Cell registration failed")
            return UITableViewCell()
        }
        
        let mealDBRecipe = recipes[indexPath.row]
        let apiRecipe = TheMealDBService.shared.convertToAPIRecipe(mealDBRecipe)
        let recipe = RecipesAPIService.shared.convertToRecipe(apiRecipe)
        
        cell.configure(with: recipe)
        
        return cell
    }
}

extension TheMealDBViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard !isLoading && !isLoadingMore else { return }
        
        let mealDBRecipe = recipes[indexPath.row]
        let apiRecipe = TheMealDBService.shared.convertToAPIRecipe(mealDBRecipe)
        let recipe = RecipesAPIService.shared.convertToRecipe(apiRecipe)
        
        if #available(iOS 13.0, *) {
            let previewVC = RecipePreviewViewController(recipe: recipe, apiRecipe: apiRecipe)
            previewVC.delegate = self
            navigationController?.pushViewController(previewVC, animated: true)
        } else {
            let categoriesVC = CategoriesSelectionViewController()
            categoriesVC.delegate = self
            categoriesVC.apiRecipe = apiRecipe
            navigationController?.pushViewController(categoriesVC, animated: true)
        }
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
        
        let lastRowIndex = tableView.numberOfRows(inSection: 0) - 1
        if indexPath.row == lastRowIndex && hasMoreRecipes && !isLoadingMore && !isLoading {
            if let category = selectedCategory {
                loadRecipesByCategory(category, append: true)
            } else {
                loadRandomRecipes(append: true)
            }
        }
    }
}

extension TheMealDBViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CategoryCollectionViewCell.cellIdentifier,
            for: indexPath
        ) as? CategoryCollectionViewCell else {
            assertionFailure("Category cell registration failed")
            return UICollectionViewCell()
        }
        
        if indexPath.item == 0 {
            cell.configure(with: "All Recipes", isSelected: selectedCategory == nil)
        } else {
            let category = categories[indexPath.item - 1]
            let categoryName = category.strCategory ?? ""
            cell.configure(with: categoryName, isSelected: selectedCategory == categoryName)
        }
        
        return cell
    }
}

extension TheMealDBViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            selectedCategory = nil
            loadRandomRecipes()
        } else {
            let category = categories[indexPath.item - 1]
            if let categoryName = category.strCategory {
                selectedCategory = categoryName
                loadRecipesByCategory(categoryName)
            }
        }
        collectionView.reloadData()
    }
}

extension TheMealDBViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 80, height: 90)
    }
}

extension TheMealDBViewController: CategoriesSelectionViewControllerDelegate {
    func didAddRecipe() {
    }
}

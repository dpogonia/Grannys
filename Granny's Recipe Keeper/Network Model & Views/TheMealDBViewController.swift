//
//  TheMealDBViewController.swift
//  Granny's Recipe Keeper
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//  Refactored to CleanSwift (VIP) Architecture
//

import UIKit

// ДЗ CLEANSWIFT: ViewController - отвечает только за UI
// ViewController Interactor Worker Interactor Presenter ViewController
// ViewController не содержит бизнес-логику, только отображение и взаимодействие с пользователем

class TheMealDBViewController: UIViewController {
    
    // CleanSwift Components (VIP)
    var interactor: TheMealDBBusinessLogic?
    var router: (NSObjectProtocol & TheMealDBRoutingLogic & TheMealDBDataPassing)?
    
    // UI State
    private var displayedRecipes: [LoadRecipes.ViewModel.DisplayedRecipe] = []
    private var displayedCategories: [LoadCategories.ViewModel.DisplayedCategory] = []
    private var displayedCountries: [LoadCountries.ViewModel.DisplayedCountry] = []
    private var displayedIngredients: [LoadIngredients.ViewModel.DisplayedIngredient] = []
    
    private var isLoading = false
    private var isLoadingMore = false
    private var hasMoreRecipes = true
    private var selectedCategoryIndex: Int?
    
    private let pageSize = 10
    
    private let categoriesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        // Делаем фон прозрачным, чтобы совпадал с основным фоном экрана
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    private let countriesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    private let countriesLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Filter by Country"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let ingredientsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Filter by Ingredient"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let ingredientsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        // Прозрачный фон, чтобы подложка была единой с фоном view
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    private let refreshControl: UIRefreshControl = {
        return UIRefreshControl()
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let randomButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(systemName: "shuffle"), style: .plain, target: nil, action: nil)
    }()
    
    private let searchButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .search, target: nil, action: nil)
    }()
    
    private let filterButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"), style: .plain, target: nil, action: nil)
    }()
    
    private let backButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: nil, action: nil)
    }()
    
    private let languageButton: UIBarButtonItem = {
        let item = UIBarButtonItem(image: UIImage(systemName: "character.book.closed"), style: .plain, target: nil, action: nil)
        item.accessibilityLabel = "Recipe language"
        return item
    }()
    
    // Object lifecycle
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // Создаем и связываем все компоненты CleanSwift: Interactor, Presenter, Router
    private func setup() {
        let viewController = self
        let interactor = TheMealDBInteractor()
        let presenter = TheMealDBPresenter()
        let router = TheMealDBRouter()
        
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
    }
    
    // View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationBar()
        setupTableView()
        setupConstraints()
        
        // Загрузка данных через Interactor
        interactor?.loadCachedRecipes()
        
        let loadCategoriesRequest = LoadCategories.Request()
        interactor?.loadCategories(request: loadCategoriesRequest)
        
        // ДЗ MOYA: Загрузка стран через Moya API (теперь через Interactor)
        let loadCountriesRequest = LoadCountries.Request()
        interactor?.loadCountries(request: loadCountriesRequest)
        
        let loadIngredientsRequest = LoadIngredients.Request()
        interactor?.loadIngredients(request: loadIngredientsRequest)
        
        let loadRecipesRequest = LoadRecipes.Request(
            filterType: .random,
            append: false,
            offset: 0,
            limit: pageSize
        )
        interactor?.loadRecipes(request: loadRecipesRequest)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Делаем фон под навбаром таким же, как и у остального экрана
        let backgroundColor: UIColor = .systemBackground
        view.backgroundColor = backgroundColor
        
        guard let navController = navigationController else { return }
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
    
    // Actions
    
    @objc private func didTapRandomButton() {
        activityIndicator.startAnimating()
        let request = LoadRandomRecipe.Request()
        interactor?.loadRandomRecipe(request: request)
    }
    
    @objc private func didTapSearchButton() {
        router?.routeToSearch()
    }
    
    @objc private func didTapFilterButton() {
        guard let dataStore = router?.dataStore else { return }
        
        router?.routeToFilters(
            areas: dataStore.areas,
            ingredients: dataStore.ingredients,
            selectedArea: nil,
            selectedIngredient: nil
        )
    }
    
    @objc private func didTapBack() {
        router?.routeBack()
    }
    
    @objc private func didTapLanguageButton() {
        let current = TranslationSettings.shared.preferredLanguage
        
        let alert = UIAlertController(
            title: "Recipe Language",
            message: "Select language for recipe translations",
            preferredStyle: .actionSheet
        )
        
        for language in AppLanguage.allCases {
            let title = language.displayName + (language == current ? " ✓" : "")
            let action = UIAlertAction(title: title, style: .default) { _ in
                TranslationSettings.shared.preferredLanguage = language
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = languageButton
        }
        
        present(alert, animated: true)
    }
    
    @objc private func refreshData() {
        guard let dataStore = router?.dataStore else { return }
        
        // Обновляем рецепты с теми же фильтрами, которые были применены до pull-to-refresh
        let filterType: LoadRecipes.Request.FilterType
        if let lastFilter = dataStore.lastFilterType {
            filterType = lastFilter
        } else if let category = dataStore.selectedCategory {
            filterType = .category(category)
        } else {
            filterType = .random
        }
        
        let request = LoadRecipes.Request(
            filterType: filterType,
            append: false,
            offset: 0,
            limit: pageSize
        )
        interactor?.loadRecipes(request: request)
    }
    
    
    private func updateTitle(_ title: String) {
        navigationItem.titleView = nil
        navigationItem.title = nil
        navigationItem.accessibilityLabel = title
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
        updateTitle("TheMealDB Recipes")
    }
    
    private func setupNavigationBar() {
        setupBarButtons()
        navigationItem.leftBarButtonItem = backButton
        navigationItem.rightBarButtonItems = [randomButton, searchButton, filterButton, languageButton]
    }
    
    private func setupBarButtons() {
        randomButton.target = self
        randomButton.action = #selector(didTapRandomButton)
        searchButton.target = self
        searchButton.action = #selector(didTapSearchButton)
        filterButton.target = self
        filterButton.action = #selector(didTapFilterButton)
        backButton.target = self
        backButton.action = #selector(didTapBack)
        languageButton.target = self
        languageButton.action = #selector(didTapLanguageButton)
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }
    
    private func setupTableView() {
        view.addSubview(categoriesCollectionView)
        view.addSubview(tableView)
        
        setupCollectionViews()
        
        tableView.register(
            RecipeTableViewCell.self,
            forCellReuseIdentifier: RecipeTableViewCell.cellIdentifier
        )
        tableView.register(
            SkeletonLoadingCell.self,
            forCellReuseIdentifier: SkeletonLoadingCell.cellIdentifier
        )
        tableView.refreshControl = refreshControl
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func setupCollectionViews() {
        categoriesCollectionView.dataSource = self
        categoriesCollectionView.delegate = self
        categoriesCollectionView.register(
            CategoryCollectionViewCell.self,
            forCellWithReuseIdentifier: CategoryCollectionViewCell.cellIdentifier
        )
        
        countriesCollectionView.register(
            CountryCollectionViewCell.self,
            forCellWithReuseIdentifier: CountryCollectionViewCell.cellIdentifier
        )
        
        ingredientsCollectionView.register(
            IngredientCollectionViewCell.self,
            forCellWithReuseIdentifier: IngredientCollectionViewCell.cellIdentifier
        )
    }
    
    private func setupConstraints() {
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            categoriesCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            categoriesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoriesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoriesCollectionView.heightAnchor.constraint(equalToConstant: 100),
            
            tableView.topAnchor.constraint(equalTo: categoriesCollectionView.bottomAnchor, constant: 8),
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

// UITableViewDataSource

extension TheMealDBViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading {
            return 5
        }
        return displayedRecipes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isLoading {
            return dequeueSkeletonCell(for: tableView, at: indexPath)
        }
        
        return dequeueAndConfigureRecipeCell(for: tableView, at: indexPath)
    }
    
    private func dequeueSkeletonCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SkeletonLoadingCell.cellIdentifier,
            for: indexPath
        ) as? SkeletonLoadingCell else {
            assertionFailure("Skeleton cell registration failed")
            return UITableViewCell()
        }
        return cell
    }
    
    private func dequeueAndConfigureRecipeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: RecipeTableViewCell.cellIdentifier,
            for: indexPath
        ) as? RecipeTableViewCell else {
            assertionFailure("Cell registration failed")
            return UITableViewCell()
        }
        
        configureRecipeCell(cell, at: indexPath)
        return cell
    }
    
    private func configureRecipeCell(_ cell: RecipeTableViewCell, at indexPath: IndexPath) {
        guard let dataStore = router?.dataStore,
              indexPath.row < dataStore.recipes.count else {
            return
        }
        
        let mealDBRecipe = dataStore.recipes[indexPath.row]
        let recipe = convertToRecipe(mealDBRecipe)
        cell.configure(with: recipe)
    }
    
    private func convertToRecipe(_ mealDBRecipe: TheMealDBRecipe) -> Recipe {
        let apiRecipe = TheMealDBService.shared.convertToAPIRecipe(mealDBRecipe)
        return RecipesAPIService.shared.convertToRecipe(apiRecipe)
    }
}

// UITableViewDelegate

extension TheMealDBViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard !isLoading && !isLoadingMore else { return }
        guard let dataStore = router?.dataStore, indexPath.row < dataStore.recipes.count else { return }
        
        let recipe = dataStore.recipes[indexPath.row]
        router?.routeToRecipeDetail(recipe: recipe)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row < displayedRecipes.count && cell.alpha == 1.0 {
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: 20)
            UIView.animate(withDuration: 0.3, delay: Double(indexPath.row % 10) * 0.05, options: .curveEaseOut, animations: {
                cell.alpha = 1
                cell.transform = .identity
            })
        }
        
        let lastRowIndex = tableView.numberOfRows(inSection: 0) - 1
        if indexPath.row == lastRowIndex && hasMoreRecipes && !isLoadingMore && !isLoading {
            guard let dataStore = router?.dataStore else { return }
            
            let filterType: LoadRecipes.Request.FilterType
            if let lastFilter = dataStore.lastFilterType {
                filterType = lastFilter
            } else if let category = dataStore.selectedCategory {
                filterType = .category(category)
            } else {
                filterType = .random
            }
            
            let request = LoadRecipes.Request(
                filterType: filterType,
                append: true,
                offset: dataStore.currentOffset,
                limit: pageSize
            )
            isLoadingMore = true
            interactor?.loadRecipes(request: request)
        }
    }
}

// UICollectionViewDataSource

extension TheMealDBViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayedCategories.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CategoryCollectionViewCell.cellIdentifier,
            for: indexPath
        ) as? CategoryCollectionViewCell else {
            assertionFailure("Category cell registration failed")
            return UICollectionViewCell()
        }
        
        configureCategoryCell(cell, at: indexPath)
        return cell
    }
    
    private func configureCategoryCell(_ cell: CategoryCollectionViewCell, at indexPath: IndexPath) {
        if indexPath.item == 0 {
            configureAllRecipesCell(cell)
        } else {
            configureCategoryItemCell(cell, at: indexPath)
        }
    }
    
    private func configureAllRecipesCell(_ cell: CategoryCollectionViewCell) {
        guard let dataStore = router?.dataStore else { return }
        let isSelected = isAllRecipesSelected(dataStore)
        cell.configure(with: "All Recipes", isSelected: isSelected)
    }
    
    private func isAllRecipesSelected(_ dataStore: TheMealDBDataStore) -> Bool {
        return dataStore.selectedCategory == nil &&
               dataStore.selectedArea == nil &&
               dataStore.selectedIngredient == nil
    }
    
    private func configureCategoryItemCell(_ cell: CategoryCollectionViewCell, at indexPath: IndexPath) {
        let category = displayedCategories[indexPath.item - 1]
        cell.configure(with: category.name, isSelected: category.isSelected)
    }
}

// UICollectionViewDelegate

extension TheMealDBViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCategoryIndex = indexPath.item
        let request = SelectCategory.Request(categoryIndex: indexPath.item)
        interactor?.selectCategory(request: request)
        categoriesCollectionView.reloadData()
    }
}

extension TheMealDBViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 95, height: 100)
    }
}

extension TheMealDBViewController: CategoriesSelectionViewControllerDelegate {
    func didAddRecipe() {
    }
}

// TheMealDBDisplayLogic

extension TheMealDBViewController: TheMealDBDisplayLogic {
    
    func displayCategories(viewModel: LoadCategories.ViewModel) {
        DispatchQueue.main.async { [weak self] in
            self?.displayedCategories = viewModel.categories
            self?.categoriesCollectionView.reloadData()
            
            if let errorMessage = viewModel.errorMessage {
                print("❌ Categories error: \(errorMessage)")
            }
        }
    }
    
    func displayCountries(viewModel: LoadCountries.ViewModel) {
        DispatchQueue.main.async { [weak self] in
            self?.displayedCountries = viewModel.countries
            // Страны не отображаются напрямую, используются через фильтры
            
            if let errorMessage = viewModel.errorMessage {
                print("❌ Countries error: \(errorMessage)")
            } else {
                print("✅ Loaded \(viewModel.countries.count) areas")
            }
        }
    }
    
    func displayIngredients(viewModel: LoadIngredients.ViewModel) {
        DispatchQueue.main.async { [weak self] in
            self?.displayedIngredients = viewModel.ingredients
            // Ингредиенты не отображаются напрямую, используются через фильтры
            
            if let errorMessage = viewModel.errorMessage {
                print("❌ Ingredients error: \(errorMessage)")
            } else {
                print("✅ Loaded \(viewModel.ingredients.count) ingredients")
            }
        }
    }
    
    func displayRecipes(viewModel: LoadRecipes.ViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isLoading = false
            self.isLoadingMore = false
            self.activityIndicator.stopAnimating()
            self.refreshControl.endRefreshing()
            self.hasMoreRecipes = viewModel.hasMore
            
            if viewModel.shouldAppend {
                let startIndex = self.displayedRecipes.count
                self.displayedRecipes.append(contentsOf: viewModel.recipes)
                let indexPaths = (startIndex..<self.displayedRecipes.count).map { IndexPath(row: $0, section: 0) }
                self.tableView.insertRows(at: indexPaths, with: .fade)
            } else {
                self.displayedRecipes = viewModel.recipes
                self.updateTitle(viewModel.title)
                self.tableView.reloadData()
                self.animateCellsAppearance()
            }
            
            if let errorMessage = viewModel.errorMessage {
                if !viewModel.shouldAppend {
                    self.showAlert(title: "Error", message: errorMessage)
                }
            }
            
            if viewModel.recipes.isEmpty && !viewModel.shouldAppend {
                self.showAlert(title: "No Results Found", message: "Try changing your filters or search query")
            }
        }
    }
    
    func displaySelectedCategory(viewModel: SelectCategory.ViewModel) {
        DispatchQueue.main.async { [weak self] in
            // Обновляем выбранную категорию в UI
            self?.categoriesCollectionView.reloadData()
        }
    }
    
    func displayRandomRecipe(viewModel: LoadRandomRecipe.ViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isLoading = false
            self.activityIndicator.stopAnimating()
            self.refreshControl.endRefreshing()
            
            if let recipe = viewModel.recipe {
                self.displayedRecipes = [recipe]
                self.updateTitle("TheMealDB Recipes")
                self.tableView.reloadData()
                self.animateCellsAppearance()
            }
            
            if let errorMessage = viewModel.errorMessage {
                self.showAlert(title: "Error", message: errorMessage)
            }
        }
    }
    
    func displayRecipeDetail(viewModel: ShowRecipeDetail.ViewModel) {
        // Навигация обрабатывается в Router через DataStore
    }
}

// TheMealDBFilterViewControllerDelegate

extension TheMealDBViewController: TheMealDBFilterViewControllerDelegate {
    func didApplyMealDBFilters(selectedArea: AreaWithFlag?, selectedRegion: CuisineRegion?, selectedIngredient: TheMealDBIngredient?) {
        let request = ApplyFilters.Request(
            selectedArea: selectedArea,
            selectedRegion: selectedRegion,
            selectedIngredient: selectedIngredient
        )
        activityIndicator.startAnimating()
        interactor?.applyFilters(request: request)
    }
}

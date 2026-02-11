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
    
    // Коллекция для отображения стран из REST Countries API
    private lazy var countriesCollectionView: UICollectionView = {
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
            CountryCollectionViewCell.self,
            forCellWithReuseIdentifier: CountryCollectionViewCell.cellIdentifier
        )
        return collectionView
    }()
    
    // Label для разделения категорий и стран
    private lazy var countriesLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Filter by Country"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()
    
    // Label для ингредиентов
    private lazy var ingredientsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Filter by Ingredient"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()
    
    // Коллекция для отображения ингредиентов
    private lazy var ingredientsCollectionView: UICollectionView = {
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
            IngredientCollectionViewCell.self,
            forCellWithReuseIdentifier: IngredientCollectionViewCell.cellIdentifier
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
    
    private lazy var filterButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            style: .plain,
            target: self,
            action: #selector(didTapFilterButton)
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
    
    @objc private func refreshData() {
        guard let dataStore = router?.dataStore else { return }
        
        let filterType: LoadRecipes.Request.FilterType
        if let category = dataStore.selectedCategory {
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
        navigationItem.leftBarButtonItem = backButton
        navigationItem.rightBarButtonItems = [randomButton, searchButton, filterButton]
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
        
        let displayedRecipe = displayedRecipes[indexPath.row]
        
        // Получаем оригинальный рецепт из DataStore для конвертации
        guard let dataStore = router?.dataStore,
              indexPath.row < dataStore.recipes.count else {
            return cell
        }
        
        let mealDBRecipe = dataStore.recipes[indexPath.row]
        let apiRecipe = TheMealDBService.shared.convertToAPIRecipe(mealDBRecipe)
        let recipe = RecipesAPIService.shared.convertToRecipe(apiRecipe)
        
        cell.configure(with: recipe)
        
        return cell
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
            if let category = dataStore.selectedCategory {
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
        
        if indexPath.item == 0 {
            guard let dataStore = router?.dataStore else { return cell }
            let isSelected = dataStore.selectedCategory == nil && 
                           dataStore.selectedArea == nil && 
                           dataStore.selectedIngredient == nil
            cell.configure(with: "All Recipes", isSelected: isSelected)
        } else {
            let category = displayedCategories[indexPath.item - 1]
            cell.configure(with: category.name, isSelected: category.isSelected)
        }
        
        return cell
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

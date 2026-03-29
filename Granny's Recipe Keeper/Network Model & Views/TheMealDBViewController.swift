//
//  TheMealDBViewController.swift
//  Granny's Recipe Keeper
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit
import FirebaseAnalytics

// ДЗ FIREBASE АНАЛИТИКА: кнопки фильтра и смены языка перевода отправляют аналитику по тапам на них (@objc private func didTapFilterButton(), @objc private func didTapLanguageButton()), также привязал Crashlitics тестом краша по кнопке @objc private func didTapSearchButton()

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
    
    private let bottomSearchContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 6
        view.isHidden = true
        view.alpha = 0
        return view
    }()
    
    private let bottomSearchTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Search recipes..."
        textField.borderStyle = .none
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .search
        textField.font = .systemFont(ofSize: 16)
        textField.textColor = .label
        return textField
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
        setupBottomSearch()
        
        interactor?.loadCachedRecipes()
        
        let loadCategoriesRequest = LoadCategories.Request()
        interactor?.loadCategories(request: loadCategoriesRequest)
        
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
        
        // Делаем фон под навбаром таким же, как и у остального экрана (динамичный systemBackground)
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
        toggleBottomSearch()
    }
    
    @objc private func didTapFilterButton() {
        guard let dataStore = router?.dataStore else { return }
        
        router?.routeToFilters(
            areas: dataStore.areas,
            ingredients: dataStore.ingredients,
            selectedArea: nil,
            selectedIngredient: nil
        )
        // ДЗ FIREBASE АНАЛИТИКА
        Analytics.logEvent("filter_button_tapped", parameters: ["user_name": "test_user", "completed": true])
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
        // ДЗ АНАЛИТИКА
        Analytics.logEvent("language_button_tapped", parameters: ["user_name": "test_user", "completed": true])

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
        navigationItem.rightBarButtonItems = [searchButton, filterButton, languageButton]
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
        tableView.separatorStyle = .none
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
    
    private func setupBottomSearch() {
        view.addSubview(bottomSearchContainer)
        bottomSearchContainer.addSubview(bottomSearchTextField)
        
        bottomSearchTextField.delegate = self
        bottomSearchTextField.addTarget(self, action: #selector(bottomSearchTextChanged(_:)), for: .editingChanged)
        
        NSLayoutConstraint.activate([
            bottomSearchContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            bottomSearchContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            bottomSearchContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            bottomSearchContainer.heightAnchor.constraint(equalToConstant: 44),
            
            bottomSearchTextField.leadingAnchor.constraint(equalTo: bottomSearchContainer.leadingAnchor, constant: 16),
            bottomSearchTextField.trailingAnchor.constraint(equalTo: bottomSearchContainer.trailingAnchor, constant: -16),
            bottomSearchTextField.topAnchor.constraint(equalTo: bottomSearchContainer.topAnchor),
            bottomSearchTextField.bottomAnchor.constraint(equalTo: bottomSearchContainer.bottomAnchor)
        ])
        
        // Добавляем небольшой нижний отступ, чтобы контент не уходил под строку поиска
        tableView.contentInset.bottom = 60
        tableView.verticalScrollIndicatorInsets.bottom = 60
    }

    private func toggleBottomSearch() {
        let shouldShow = bottomSearchContainer.isHidden
        
        if shouldShow {
            bottomSearchContainer.isHidden = false
            UIView.animate(withDuration: 0.25) {
                self.bottomSearchContainer.alpha = 1
            }
            bottomSearchTextField.becomeFirstResponder()
        } else {
            bottomSearchTextField.resignFirstResponder()
            UIView.animate(withDuration: 0.25, animations: {
                self.bottomSearchContainer.alpha = 0
            }, completion: { _ in
                self.bottomSearchContainer.isHidden = true
                // При закрытии строки поиска очищаем текст,
                // но сами результаты поиска не трогаем.
                self.bottomSearchTextField.text = ""
            })
        }
    }
    
    private func setupConstraints() {
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            categoriesCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            categoriesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoriesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // Компактная высота под одну строку чипов категорий
            categoriesCollectionView.heightAnchor.constraint(equalToConstant: 52),
            
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
        Haptics.lightImpact()
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
        // +1 для "All Recipes" (в начале) и +1 для "Shuffle" (в конце)
        return displayedCategories.count + 2
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
        // 0 — "All Recipes", последняя — "Shuffle", остальные — категории
        if indexPath.item == 0 {
            configureAllRecipesCell(cell)
        } else if indexPath.item == displayedCategories.count + 1 {
            configureShuffleCell(cell)
        } else {
            configureCategoryItemCell(cell, at: indexPath)
        }
    }
    
    private func configureAllRecipesCell(_ cell: CategoryCollectionViewCell) {
        guard let dataStore = router?.dataStore else { return }
        let isSelected = isAllRecipesSelected(dataStore)
        let title = CategoryLocalization.localizedMealDBCategoryName("All Recipes")
        cell.configure(with: title, isSelected: isSelected)
    }
    
    private func configureShuffleCell(_ cell: CategoryCollectionViewCell) {
        let title = CategoryLocalization.localizedMealDBCategoryName("Shuffle")
        cell.configure(with: title, isSelected: false)
    }
    
    private func isAllRecipesSelected(_ dataStore: TheMealDBDataStore) -> Bool {
        return dataStore.selectedCategory == nil &&
               dataStore.selectedArea == nil &&
               dataStore.selectedIngredient == nil
    }
    
    private func configureCategoryItemCell(_ cell: CategoryCollectionViewCell, at indexPath: IndexPath) {
        // Смещаемся на 1 из‑за "Shuffle" в начале
        let category = displayedCategories[indexPath.item - 1]
        let isSelected = (indexPath.item == selectedCategoryIndex)
        cell.configure(with: category.name, isSelected: isSelected)
    }
}

// UICollectionViewDelegate

extension TheMealDBViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === categoriesCollectionView {
            Haptics.selection()
        }
        
        // Ячейка "Shuffle" (в конце) работает как кнопка: просто перемешивает/открывает случайный рецепт
        if collectionView === categoriesCollectionView && indexPath.item == displayedCategories.count + 1 {
            didTapRandomButton()
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        
        selectedCategoryIndex = indexPath.item
        
        // Преобразуем индекс ячейки к индексу, ожидаемому интерактором:
        // 0 — "All Recipes", 1...N — категории.
        let categoryIndex: Int
        // Первая ячейка — "All Recipes", далее 1...N — категории.
        categoryIndex = indexPath.item
        
        let request = SelectCategory.Request(categoryIndex: categoryIndex)
        interactor?.selectCategory(request: request)
        categoriesCollectionView.reloadData()
    }
}

extension TheMealDBViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Делаем ширину чипов компактной и зависящей от текста
        let font = UIFont.systemFont(ofSize: 14, weight: .medium)
        let text: String
        if collectionView === categoriesCollectionView {
            if indexPath.item == 0 {
                text = CategoryLocalization.localizedMealDBCategoryName("All Recipes")
            } else if indexPath.item == displayedCategories.count + 1 {
                text = CategoryLocalization.localizedMealDBCategoryName("Shuffle")
            } else if indexPath.item <= displayedCategories.count {
                text = displayedCategories[indexPath.item - 1].name
            } else {
                text = ""
            }
        } else {
            text = ""
        }
        
        let padding: CGFloat = 24 // по 12pt слева и справа
        let minWidth: CGFloat = 60
        let textWidth = (text as NSString).size(withAttributes: [.font: font]).width
        let width = max(minWidth, textWidth + padding)
        
        // Высоту делаем чуть выше (~20% больше 32)
        return CGSize(width: width, height: 38)
    }
}

extension TheMealDBViewController: CategoriesSelectionViewControllerDelegate {
    func didAddRecipe() {
    }
}

// MARK: - Bottom Search

extension TheMealDBViewController: UITextFieldDelegate {
    @objc private func bottomSearchTextChanged(_ textField: UITextField) {
        // Можно запускать поиск по нажатию Return, а не на каждый символ,
        // поэтому здесь пока ничего не делаем.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let query = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !query.isEmpty else {
            return false
        }
        
        let request = SearchRecipes.Request(query: query)
        interactor?.searchRecipes(request: request)
        textField.resignFirstResponder()
        return true
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
    }
}

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

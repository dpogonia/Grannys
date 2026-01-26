//
//  RecipesViewController.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

// MARK: - RecipesViewController
// RecipesViewController - это главный экран приложения со списком рецептов
// UIViewController - это базовый класс для всех экранов в iOS
// Этот контроллер показывает список рецептов в таблице и позволяет их фильтровать, искать и редактировать
//
// АНАЛОГИЯ: Это как главная страница библиотеки - здесь видно все книги (рецепты),
// можно искать по названию, фильтровать по категориям и открывать для просмотра

class RecipesViewController: UIViewController {
    
    // Массив рецептов, которые сейчас отображаются на экране
    private var recipes: [Recipe] = []
    
    // Все доступные категории (Завтрак, Обед, Десерты и т.д.)
    private var allCategories: [Category] = []
    
    // Выбранная категория для фильтрации (nil = показать все рецепты)
    private var selectedCategory: Category?
    
    // Флаг: ищет ли пользователь рецепты сейчас
    private var isSearching = false
    
    // Set - это коллекция уникальных элементов (как множество в математике)
    // Выбранные теги для фильтрации (например, {"вегетарианский", "без глютена"})
    private var filterTags: Set<String> = []
    
    // Выбранная сложность для фильтрации (nil = любая сложность)
    private var filterDifficulty: String?
    
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
        button.tintColor = .label // Устанавливаем черный цвет для иконок и текста
        button.setTitleColor(.label, for: .normal) // Устанавливаем черный цвет для текста
        button.contentHorizontalAlignment = .left // Выравнивание по левому краю
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
            image: UIImage(systemName: "slider.horizontal.3"),
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
        iconImageView.tag = 999 // Для поиска в updateEmptyState
        
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
        
        // Анимация появления будет вызвана при показе empty state
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
        
        // Используем стандартный стиль navigation bar без кастомных настроек
        // Это даст такой же вид, как в RecipeDetailViewController
        
        // Используем fullScreen для полного белого фона без полупрозрачности
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
        navigationItem.rightBarButtonItems = [addButton, filterButton, mealDBButton]
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    func loadCategories() {
        allCategories = RecipesRepository.shared.getAllCategories()
    }
    
    func loadRecipes() {
        // Проверяем, выбрана ли категория "Избранное"
        let favoriteCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        let archiveCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")
        let isFavoriteSelected = selectedCategory?.id == favoriteCategoryId
        let isArchiveSelected = selectedCategory?.id == archiveCategoryId
        
        var loadedRecipes: [Recipe] = []
        
        if isFavoriteSelected {
            // Показываем только избранные рецепты
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
            // Показываем только архивированные рецепты
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
            // Обычная фильтрация
            if isSearching, let searchText = searchController.searchBar.text, !searchText.isEmpty {
                loadedRecipes = RecipesRepository.shared.searchRecipes(query: searchText, in: selectedCategory)
            } else {
                loadedRecipes = RecipesRepository.shared.getRecipes(in: selectedCategory, archived: false)
            }
        }
        
        // Применяем фильтры по тегам и сложности
        recipes = applyFilters(to: loadedRecipes)
        
        updateCategoryButtonTitle()
        updateEmptyState()
        tableView.reloadData()
    }
    
    private func applyFilters(to recipes: [Recipe]) -> [Recipe] {
        var filtered = recipes
        
        // Фильтр по тегам
        if !filterTags.isEmpty {
            filtered = filtered.filter { recipe in
                // Рецепт должен содержать хотя бы один из выбранных тегов
                !recipe.tags.filter { filterTags.contains($0) }.isEmpty
            }
        }
        
        // Фильтр по сложности
        if let difficulty = filterDifficulty {
            filtered = filtered.filter { recipe in
                recipe.difficulty?.lowercased() == difficulty.lowercased()
            }
        }
        
        return filtered
    }
    
    func updateEmptyState() {
        let isEmpty = recipes.isEmpty
        let wasHidden = emptyStateView.isHidden
        
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        
        // Анимация появления empty state
        if isEmpty && wasHidden {
            emptyStateView.alpha = 0
            UIView.animate(withDuration: 0.3) {
                self.emptyStateView.alpha = 1
            }
            
            // Анимация иконки с пульсацией
            if let iconImageView = emptyStateView.viewWithTag(999) as? UIImageView {
                iconImageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: [], animations: {
                    iconImageView.transform = .identity
                    iconImageView.alpha = 1
                }) { _ in
                    // Запускаем пульсирующую анимацию
                    self.startPulsingAnimation(for: iconImageView)
                }
            }
        } else if !isEmpty {
            emptyStateView.alpha = 0
            // Останавливаем пульсацию при скрытии
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
        
        // Для всех категорий используем одинаковое форматирование с иконкой
        let iconImage: UIImage?
        if isFavoriteSelected {
            // Для избранного используем сердечко
            iconImage = UIImage(systemName: "heart.fill")
        } else if isArchiveSelected {
            // Для архива используем черно-белую иконку архива
            iconImage = UIImage(systemName: "archivebox.fill")
        } else {
            // Для остальных категорий используем иконку вилки/ножа
            iconImage = UIImage(systemName: "fork.knife")
        }
        
        // Используем шрифт и размер, увеличенные на 30%
        let font = UIFont.systemFont(ofSize: 19.5, weight: .regular)
        
        let iconAttachment = NSTextAttachment()
        iconAttachment.image = iconImage?.withTintColor(.label, renderingMode: .alwaysOriginal)
        
        // Настраиваем размер иконки, увеличенный на 30%
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
        
        // Устанавливаем фиксированную ширину для одинакового выравнивания
        // Используем максимальную ширину, чтобы все категории были выровнены одинаково
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
        // CABasicAnimation - это базовая анимация Core Animation
        // Core Animation - это низкоуровневый фреймворк для анимаций (быстрее, чем UIView.animate)
        // keyPath: "transform.scale" - что анимируем (масштаб изображения)
        // АНАЛОГИЯ: Как пульс сердца - объект то увеличивается, то уменьшается
        
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        
        // fromValue - начальное значение (нормальный размер, 100%)
        pulseAnimation.fromValue = 1.0
        
        // toValue - конечное значение (увеличенный размер, 115%)
        pulseAnimation.toValue = 1.15
        
        // duration - длительность одного цикла (1 секунда)
        pulseAnimation.duration = 1.0
        
        // autoreverses - автоматически обращать анимацию
        // true означает: 1.0 -> 1.15 -> 1.0 (туда и обратно)
        pulseAnimation.autoreverses = true
        
        // repeatCount - сколько раз повторять
        // .infinity - бесконечно (пока не остановим вручную)
        pulseAnimation.repeatCount = .infinity
        
        // timingFunction - функция времени (как изменяется скорость анимации)
        // .easeInEaseOut - медленно в начале, быстро в середине, медленно в конце
        // АНАЛОГИЯ: Как автомобиль - медленно трогается, разгоняется, медленно останавливается
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // Добавляем анимацию к слою изображения
        // layer - это CALayer, низкоуровневое представление view
        // forKey: "pulsing" - имя анимации (нужно для остановки позже)
        imageView.layer.add(pulseAnimation, forKey: "pulsing")
    }
}

// MARK: - UITableViewDataSource Extension
// Extension - это расширение, которое добавляет функциональность к существующему типу
// Здесь мы добавляем методы протокола UITableViewDataSource к RecipesViewController

// UITableViewDataSource - это протокол, который требует реализации методов для работы с данными таблицы
// Протокол - это контракт: "если ты хочешь быть DataSource, ты должен реализовать эти методы"
// АНАЛОГИЯ: Как водительские права - если хочешь водить, должен знать правила

extension RecipesViewController: UITableViewDataSource {
    // Этот метод ОБЯЗАТЕЛЕН для UITableViewDataSource
    // Таблица спрашивает: "Сколько строк мне показать?"
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // recipes.count - количество рецептов в массиве
        let count = recipes.count
        
        // Обновляем состояние пустого экрана (показать/скрыть сообщение "Нет рецептов")
        updateEmptyState()
        
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // dequeueReusableCell - это ПЕРЕИСПОЛЬЗОВАНИЕ ячеек (cell reuse)
        // ВАЖНО: iOS не создаёт новую ячейку для каждого рецепта!
        // Вместо этого переиспользует ячейки, которые уже не видны на экране
        // АНАЛОГИЯ: Как театральные костюмы - актёры переодеваются, но костюмы одни и те же
        // Зачем это нужно? Экономия памяти! Вместо 1000 ячеек в памяти только ~10 видимых
        
        // guard let - это "охранник" с безопасным извлечением опционала
        // Если dequeueReusableCell вернёт nil или неправильный тип, выполнение прекратится
        // as? - безопасное приведение типа: пытается превратить UITableViewCell в RecipeTableViewCell
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: RecipeTableViewCell.cellIdentifier,
            for: indexPath
        ) as? RecipeTableViewCell else {
            // assertionFailure - останавливает выполнение в Debug режиме с сообщением
            // Это помогает найти ошибки во время разработки
            // В Release режиме не останавливает приложение
            assertionFailure("Cell registration failed")
            // Возвращаем пустую ячейку как fallback (запасной вариант)
            return UITableViewCell()
        }
        
        // indexPath.row - это номер строки в таблице (0, 1, 2, ...)
        // Получаем рецепт для этой строки
        let recipe = recipes[indexPath.row]
        
        // configure - настраивает ячейку данными рецепта
        // Это паттерн: ячейка не знает, откуда брать данные, она просто получает их
        cell.configure(with: recipe)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // willDisplay - вызывается ПЕРЕД показом ячейки на экране
        // Идеальное место для анимаций появления
        
        // Анимация появления ячейки только при первой загрузке
        // Проверяем: строка существует И ячейка полностью непрозрачна (alpha == 1.0)
        if indexPath.row < recipes.count && cell.alpha == 1.0 {
            // Начальное состояние: полностью прозрачная и смещённая вниз
            cell.alpha = 0 // Невидимая (прозрачность 0%)
            // CGAffineTransform - это преобразование (трансформация) view
            // translationX: 0, y: 20 - смещение на 20 пикселей вниз
            // АНАЛОГИЯ: Как слайд, который выезжает снизу
            cell.transform = CGAffineTransform(translationX: 0, y: 20)
            
            // UIView.animate - создаёт анимацию
            // withDuration: 0.3 - длительность 0.3 секунды
            // delay: - задержка перед началом анимации
            //   indexPath.row % 10 - это ОПЕРАТОР МОДУЛО (остаток от деления)
            //   % - возвращает остаток от деления первого числа на второе
            //   Примеры:
            //     - 0 % 10 = 0 (0 делится на 10 без остатка)
            //     - 5 % 10 = 5 (5 не делится на 10, остаток 5)
            //     - 10 % 10 = 0 (10 делится на 10 без остатка)
            //     - 15 % 10 = 5 (15 = 10 + 5, остаток 5)
            //   Результат всегда от 0 до 9 (циклически повторяется)
            //   * 0.05 - умножаем на 0.05 секунды
            //   Результат: каждая ячейка появляется с небольшой задержкой (эффект волны)
            //   Ячейки 0, 10, 20 появляются одновременно, затем 1, 11, 21 и т.д.
            // options: .curveEaseOut - плавное замедление в конце (как мяч, который подпрыгивает)
            UIView.animate(withDuration: 0.3, delay: Double(indexPath.row % 10) * 0.05, options: .curveEaseOut, animations: {
                // Конечное состояние: полностью видимая и на своём месте
                cell.alpha = 1 // Полностью видимая
                cell.transform = .identity // .identity - это "без трансформации" (исходное положение)
            })
        }
    }
}

// MARK: - UITableViewDelegate Extension
// UITableViewDelegate - это протокол для обработки событий таблицы
// Отвечает на вопросы: "Что делать при нажатии?", "Какой высоты должна быть ячейка?" и т.д.

extension RecipesViewController: UITableViewDelegate {
    // Опциональный метод: задаёт высоту ячейки
    // Если не реализован, используется высота по умолчанию или automaticDimension
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Возвращаем фиксированную высоту 96 пикселей для всех ячеек
        // CGFloat - это тип для чисел с плавающей точкой (дробные числа)
        return 96
    }
    
    // Вызывается, когда пользователь нажимает на ячейку
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // deselectRow - убирает выделение с ячейки (она больше не подсвечена)
        // animated: true - с анимацией (плавно исчезает выделение)
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Получаем рецепт, на который нажали
        let selectedRecipe = recipes[indexPath.row]
        
        // Создаём экран деталей рецепта
        let detailViewController = RecipeDetailViewController(recipe: selectedRecipe)
        
        // Устанавливаем себя как делегата
        // self - это RecipesViewController
        // Теперь RecipeDetailViewController сможет уведомить нас об изменениях
        detailViewController.delegate = self
        
        // Добавляем анимацию появления ячейки
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
    
    // leadingSwipeActionsConfiguration - действия при свайпе СЛЕВА НАПРАВО
    // Свайп - это жест "провести пальцем" по ячейке
    // Возвращает UISwipeActionsConfiguration? - опционально (может быть nil)
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let recipe = recipes[indexPath.row]
        let isFavorite = recipe.isFavorite
        
        // UIContextualAction - это действие, которое появляется при свайпе
        // style: .normal - обычный стиль (не деструктивный, как удаление)
        // title: nil - без текста (только иконка)
        // Замыкание { } - что делать, когда пользователь нажмёт на действие
        
        // ВАЖНО: completionHandler - это замыкание, которое МОЖНО вызвать
        // completionHandler(true) - говорим системе: "действие выполнено успешно"
        // completionHandler(false) - "действие отменено"
        // Система использует это, чтобы скрыть кнопки действия после выполнения
        let favoriteAction = UIContextualAction(style: .normal, title: nil) { [weak self] (action, view, completionHandler) in
            // Переключаем избранное (добавляем/убираем из избранного)
            RecipesRepository.shared.toggleFavorite(recipe)
            
            // Обновляем локальный список рецептов
            // Получаем обновлённый рецепт из базы данных
            if let updatedRecipe = RecipesRepository.shared.getRecipe(by: recipe.id) {
                // Обновляем рецепт в массиве
                self?.recipes[indexPath.row] = updatedRecipe
                // Перезагружаем ячейку, чтобы показать новое состояние (сердечко заполнено/пусто)
                tableView.reloadRows(at: [indexPath], with: .none)
            }
            
            // Говорим системе, что действие выполнено успешно
            completionHandler(true)
        }
        
        // Устанавливаем иконку в зависимости от состояния
        // Тернарный оператор: если избранное - показываем "сердечко зачёркнутое", иначе - "сердечко заполненное"
        favoriteAction.image = UIImage(systemName: isFavorite ? "heart.slash.fill" : "heart.fill")
        // Цвет фона: если избранное - серый, иначе - красный
        favoriteAction.backgroundColor = isFavorite ? .systemGray : .systemRed
        
        // Возвращаем конфигурацию с действиями
        // Массив может содержать несколько действий (они появятся рядом)
        return UISwipeActionsConfiguration(actions: [favoriteAction])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let recipe = recipes[indexPath.row]
        let archiveCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")
        let isArchiveSelected = selectedCategory?.id == archiveCategoryId
        
        if isArchiveSelected {
            // В архиве показываем действие восстановления
            let unarchiveAction = UIContextualAction(style: .normal, title: nil) { [weak self] (action, view, completionHandler) in
                RecipesRepository.shared.unarchiveRecipe(recipe)
                self?.recipes.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                self?.updateEmptyState()
                completionHandler(true)
            }
            unarchiveAction.image = UIImage(systemName: "tray.and.arrow.up.fill")
            unarchiveAction.backgroundColor = .systemGreen
            
            // Действие удаления
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
            // В обычном списке показываем архивирование и удаление
            let archiveAction = UIContextualAction(style: .normal, title: nil) { [weak self] (action, view, completionHandler) in
                RecipesRepository.shared.archiveRecipe(recipe)
                self?.recipes.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                self?.updateEmptyState()
                completionHandler(true)
            }
            archiveAction.image = UIImage(systemName: "archivebox.fill")
            archiveAction.backgroundColor = .systemOrange
            
            // Действие удаления
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
    func didApplyFilters(selectedTags: Set<String>, selectedDifficulty: String?) {
        filterTags = selectedTags
        filterDifficulty = selectedDifficulty
        loadRecipes()
    }
}


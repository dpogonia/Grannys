//
//  CategoriesSelectionViewController.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

// MARK: - CategoriesSelectionViewControllerDelegate
// Протокол для уведомления о добавлении рецепта
/*
 // 1. Протокол определяет "правила игры"
 protocol CategoriesSelectionViewControllerDelegate {
     func didAddRecipe() // "Кто подписывается, должен уметь обработать добавление рецепта"
 }

 // 2. Экран выбора категорий говорит: "Когда рецепт добавлен, сообщи об этом делегату"
 delegate?.didAddRecipe()

 // 3. RecipesViewController говорит: "Я умею обрабатывать это событие!"
 extension RecipesViewController: CategoriesSelectionViewControllerDelegate {
     func didAddRecipe() {
         loadRecipes() // "Когда рецепт добавлен, обновлю список"
     }
 }
 */
protocol CategoriesSelectionViewControllerDelegate: AnyObject {
    func didAddRecipe() // Рецепт был добавлен в базу данных
}

// MARK: - CategoriesSelectionViewController
// CategoriesSelectionViewController - это экран для выбора категорий при добавлении рецепта
// Когда пользователь находит рецепт в TheMealDB, он может добавить его к себе, выбрав категории для него (можно выбрать несколько)
class CategoriesSelectionViewController: UIViewController {
    
    // Рецепт из API, который нужно сохранить
    var apiRecipe: APIRecipe?
    
    // Делегат для уведомления о сохранении рецепта
    weak var delegate: CategoriesSelectionViewControllerDelegate?
    
    // Все доступные категории из базы данных
    private var allCategories: [Category] = []
    
    // Set выбранных категорий (используем UUID для идентификации)
    private var selectedCategories: Set<UUID> = []
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CategoryCell")
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationBar()
        loadCategories()
        setupTableView()
        setupConstraints()
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        title = "Select Categories"
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(didTapSave)
        )
    }
    
    @objc private func didTapSave() {
        guard let apiRecipe = apiRecipe else {
            dismiss(animated: true)
            return
        }
        
        // filter - фильтрует массив, оставляя только те категории, которые выбраны
        // $0 - это каждый элемент массива allCategories (каждая Category)
        // selectedCategories.contains($0.id) - проверяет, есть ли ID категории в Set выбранных
        // Результат: массив только выбранных категорий
        let categories = allCategories.filter { selectedCategories.contains($0.id) }
        
        // Преобразуем рецепт из API в наш формат Recipe
        let recipe = RecipesAPIService.shared.convertToRecipe(apiRecipe, categories: categories)
        
        // Загружаем изображение если есть URL
        // if let imageURL - безопасное извлечение опционала
        // , !imageURL.isEmpty - дополнительное условие: строка не пустая
        // Запятая означает И: оба условия должны выполняться
        if let imageURL = apiRecipe.image, !imageURL.isEmpty {
            
            // loadImage - асинхронная функция (загрузка из интернета может занять время)
            // Замыкание { result in ... } вызовится, когда изображение загрузится
            RecipesAPIService.shared.loadImage(from: imageURL) { [weak self] result in
                // ВАЖНО: Загрузка происходит в фоновом потоке, но UI обновлять нужно в главном потоке!
                // DispatchQueue.main.async - переключаемся на главный поток (UI поток)
                // Все операции с интерфейсом ДОЛЖНЫ происходить в главном потоке
                DispatchQueue.main.async {
                    // finalRecipe - финальная версия рецепта для сохранения
                    var finalRecipe = recipe
                    
                    // if case - это PATTERN MATCHING (сопоставление с образцом) для enum Result
                    // Result имеет два варианта: .success(значение) или .failure(ошибка)
                    // if case .success(let image) = result означает:
                    // "если result это .success, извлеки значение в константу image"
                    if case .success(let image) = result {
                        // jpegData - преобразует UIImage в данные (бинарный формат)
                        // compressionQuality: 0.8 - качество сжатия (0.0-1.0)
                        // 0.8 - хороший баланс между качеством и размером файла
                        finalRecipe.imageData = image.jpegData(compressionQuality: 0.8)
                    }
                    // Если был .failure, imageData останется nil (изображение не загрузилось)
                    
                    // Сохраняем рецепт в базу данных
                    RecipesRepository.shared.saveRecipe(finalRecipe)
                    
                    // Уведомляем делегата, что рецепт добавлен
                    self?.delegate?.didAddRecipe()
                    
                    // Возвращаемся к корневому экрану после сохранения
                    // popToRootViewController - возвращает на самый первый экран в navigation stack
                    self?.navigationController?.popToRootViewController(animated: true)
                }
            }
        } else {
            // Если URL нет или пустой, сохраняем рецепт без изображения
            // TODO: Добавить дефолтное изображение
            RecipesRepository.shared.saveRecipe(recipe)
            delegate?.didAddRecipe()
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    private func loadCategories() {
        allCategories = RecipesRepository.shared.getAllCategories()
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

extension CategoriesSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allCategories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        let category = allCategories[indexPath.row]
        cell.textLabel?.text = category.name
        cell.accessoryType = selectedCategories.contains(category.id) ? .checkmark : .none
        return cell
    }
}

extension CategoriesSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let category = allCategories[indexPath.row]
        if selectedCategories.contains(category.id) {
            selectedCategories.remove(category.id)
        } else {
            selectedCategories.insert(category.id)
        }
        
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}

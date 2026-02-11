//
//  CategoriesViewController.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

protocol CategoriesViewControllerDelegate: AnyObject {
    func didSelectCategory(_ category: Category?)
}

class CategoriesViewController: UIViewController {
    
    weak var delegate: CategoriesViewControllerDelegate?
    
    var selectedCategory: Category?
    
    private var allCategories: [Category] = []
    
    private var isSpecialCategoriesHidden = false
    
    private var isFixedCategoriesHidden = false
    
    private var fixedCategories: [Category] = []
    
    private var customCategories: [Category] = []
    
    private enum HideMode: Int {
        case showAll = 0
        case hideSpecial = 1
        case hideSpecialAndFixed = 2
    }
    
    private var currentHideMode: HideMode {
        if isFixedCategoriesHidden {
            return .hideSpecialAndFixed
        } else if isSpecialCategoriesHidden {
            return .hideSpecial
        }
        return .showAll
    }
    
    private enum Section: Int, CaseIterable {
        case allRecipes = 0
        case fixedCategories = 1
        case customCategories = 2
        case specialCategories = 3
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CategoryCell")
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        loadCategories()
        loadSettings()
        setupTableView()
        setupConstraints()
        setupNavigationBar()
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        
        let titleLabel = UILabel()
        titleLabel.text = "CATEGORIES"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.5
        
        // Определяем доступную ширину для заголовка
        let screenWidth = UIScreen.main.bounds.width
        let backButtonSpace: CGFloat = 60 // пространство для кнопки назад
        let rightButtonsSpace: CGFloat = 140 // пространство для 3 кнопок справа
        let availableWidth = screenWidth - backButtonSpace - rightButtonsSpace - 32 // 32 для отступов
        
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: max(availableWidth, 100), height: 44))
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        navigationItem.titleView = containerView
    }
    
    private func setupNavigationBar() {
        let hideButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(didTapHideButton)
        )
        
        let editButton = UIBarButtonItem(
            image: UIImage(systemName: "pencil"),
            style: .plain,
            target: self,
            action: #selector(didTapEditButton)
        )
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(didTapAddCategory)
        )
        navigationItem.rightBarButtonItems = [addButton, editButton, hideButton]
        updateHideButton()
    }
    
    @objc private func didTapEditButton() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        updateEditButton()
    }
    
    private func updateEditButton() {
        if var rightBarButtonItems = navigationItem.rightBarButtonItems,
           rightBarButtonItems.count >= 3 {
            if tableView.isEditing {
                let doneButton = UIBarButtonItem(
                    image: UIImage(systemName: "checkmark"),
                    style: .plain,
                    target: self,
                    action: #selector(didTapEditButton)
                )
                rightBarButtonItems[1] = doneButton
            } else {
                let editButton = UIBarButtonItem(
                    image: UIImage(systemName: "pencil"),
                    style: .plain,
                    target: self,
                    action: #selector(didTapEditButton)
                )
                rightBarButtonItems[1] = editButton
            }
            navigationItem.rightBarButtonItems = rightBarButtonItems
        }
    }
    
    @objc private func didTapHideButton() {
        switch currentHideMode {
        case .showAll:
            isSpecialCategoriesHidden = true
            isFixedCategoriesHidden = false
        case .hideSpecial:
            isSpecialCategoriesHidden = true
            isFixedCategoriesHidden = true
        case .hideSpecialAndFixed:
            isSpecialCategoriesHidden = false
            isFixedCategoriesHidden = false
        }
        
        saveSettings()
        updateHideButton()
        tableView.reloadData()
    }
    
    private func loadSettings() {
        isSpecialCategoriesHidden = CoreDataManager.shared.isSpecialCategoriesHidden()
        isFixedCategoriesHidden = UserDefaults.standard.bool(forKey: "isFixedCategoriesHidden")
    }
    
    private func saveSettings() {
        CoreDataManager.shared.saveSpecialCategoriesHidden(isSpecialCategoriesHidden)
        UserDefaults.standard.set(isFixedCategoriesHidden, forKey: "isFixedCategoriesHidden")
    }
    
    private func updateHideButton() {
        if let rightBarButtonItems = navigationItem.rightBarButtonItems,
           rightBarButtonItems.count >= 3 {
            let hideButton = rightBarButtonItems[2]
            
            switch currentHideMode {
            case .showAll:
                hideButton.image = UIImage(systemName: "xmark")
            case .hideSpecial:
                hideButton.image = UIImage(systemName: "xmark.circle")
            case .hideSpecialAndFixed:
                hideButton.image = UIImage(systemName: "fork.knife")
            }
            hideButton.tintColor = .label
        }
    }
    
    @objc private func didTapAddCategory() {
        let alert = UIAlertController(title: "New Category", message: "Enter category name", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Category name"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let textField = alert.textFields?.first,
                  let name = textField.text,
                  !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                return
            }
            
            let maxOrder = self?.customCategories.map { $0.order }.max() ?? -1
            let category = Category(name: name.trimmingCharacters(in: .whitespaces), isDefault: false, order: maxOrder + 1)
            RecipesRepository.shared.saveCategory(category)
            self?.loadCategories()
        })
        
        present(alert, animated: true)
    }
    
    private func loadCategories() {
        allCategories = RecipesRepository.shared.getAllCategories()
        
        fixedCategories = allCategories.filter { ["Breakfast", "Lunch", "Dinner"].contains($0.name) }
            .sorted { $0.order < $1.order }
        
        customCategories = allCategories.filter { !["Breakfast", "Lunch", "Dinner"].contains($0.name) }
            .sorted { $0.order < $1.order }
        
        tableView.reloadData()
    }
    
    private func saveCategoryOrder() {
        for (index, category) in customCategories.enumerated() {
            var updatedCategory = category
            updatedCategory.order = Int32(index)
            RecipesRepository.shared.saveCategory(updatedCategory)
        }
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

extension CategoriesViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if isFixedCategoriesHidden {
            return 1
        } else if isSpecialCategoriesHidden {
            return 2
        }
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFixedCategoriesHidden {
            return customCategories.count
        } else if isSpecialCategoriesHidden {
            switch section {
            case 0:
                return fixedCategories.count
            case 1:
                return customCategories.count
            default:
                return 0
            }
        }
        
        let sectionType = Section(rawValue: section) ?? .allRecipes
        
        switch sectionType {
        case .allRecipes:
            return 1
        case .fixedCategories:
            return fixedCategories.count
        case .customCategories:
            return customCategories.count
        case .specialCategories:
            return 2 // Favorites, Archive
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        
        cell.textLabel?.text = nil
        cell.textLabel?.attributedText = nil
        cell.detailTextLabel?.text = nil
        cell.accessoryType = .none
        
        if isFixedCategoriesHidden {
            let category = customCategories[indexPath.row]
            cell.textLabel?.text = category.name
            cell.detailTextLabel?.text = nil
            cell.accessoryType = selectedCategory?.id == category.id ? .checkmark : .none
        } else if isSpecialCategoriesHidden {
            switch indexPath.section {
            case 0:
                let category = fixedCategories[indexPath.row]
                cell.textLabel?.text = category.name
                cell.detailTextLabel?.text = nil
                cell.accessoryType = selectedCategory?.id == category.id ? .checkmark : .none
            case 1:
                let category = customCategories[indexPath.row]
                cell.textLabel?.text = category.name
                cell.detailTextLabel?.text = nil
                cell.accessoryType = selectedCategory?.id == category.id ? .checkmark : .none
            default:
                break
            }
        } else {
            let sectionType = Section(rawValue: indexPath.section) ?? .allRecipes
            
            switch sectionType {
            case .allRecipes:
                cell.textLabel?.text = "All Recipes"
                cell.detailTextLabel?.text = nil
                
                cell.accessoryType = selectedCategory == nil ? .checkmark : .none
                
            case .fixedCategories:
                let category = fixedCategories[indexPath.row]
                cell.textLabel?.text = category.name
                cell.detailTextLabel?.text = nil
                
                cell.accessoryType = selectedCategory?.id == category.id ? .checkmark : .none
                
            case .customCategories:
                let category = customCategories[indexPath.row]
                cell.textLabel?.text = category.name
                cell.detailTextLabel?.text = nil
                cell.accessoryType = selectedCategory?.id == category.id ? .checkmark : .none
                
            case .specialCategories:
                if indexPath.row == 0 {
                    cell.textLabel?.text = "Favorites"
                    
                    let favoriteCount = RecipesRepository.shared.getFavoriteRecipes().count
                    
                    cell.detailTextLabel?.text = favoriteCount > 0 ? "\(favoriteCount)" : nil
                    
                    let favoriteCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")
                    
                    let isFavoriteSelected = selectedCategory?.id == favoriteCategoryId
                    cell.accessoryType = isFavoriteSelected ? .checkmark : .none
                } else if indexPath.row == 1 {
                    cell.textLabel?.text = "Archive"
                    
                    let archiveCount = RecipesRepository.shared.getAllRecipes(archived: true).count
                    
                    cell.detailTextLabel?.text = archiveCount > 0 ? "\(archiveCount)" : nil
                    let archiveCategoryId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")
                    let isArchiveSelected = selectedCategory?.id == archiveCategoryId
                    cell.accessoryType = isArchiveSelected ? .checkmark : .none
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if isFixedCategoriesHidden {
            return indexPath.section == 0
        } else if isSpecialCategoriesHidden {
            return indexPath.section == 1
        }
        let sectionType = Section(rawValue: indexPath.section) ?? .allRecipes
        
        return sectionType == .customCategories
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let customSectionIndex: Int
        if isFixedCategoriesHidden {
            customSectionIndex = 0
        } else if isSpecialCategoriesHidden {
            customSectionIndex = 1
        } else {
            customSectionIndex = Section.customCategories.rawValue
        }
        
        guard sourceIndexPath.section == customSectionIndex,
              destinationIndexPath.section == customSectionIndex else {
            return
        }
        
        let movedCategory = customCategories.remove(at: sourceIndexPath.row)
        
        customCategories.insert(movedCategory, at: destinationIndexPath.row)
        
        saveCategoryOrder()
    }
}

extension CategoriesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if isFixedCategoriesHidden {
            selectedCategory = customCategories[indexPath.row]
        } else if isSpecialCategoriesHidden {
            switch indexPath.section {
            case 0:
                selectedCategory = fixedCategories[indexPath.row]
            case 1:
                selectedCategory = customCategories[indexPath.row]
            default:
                break
            }
        } else {
            let sectionType = Section(rawValue: indexPath.section) ?? .allRecipes
            
            switch sectionType {
            case .allRecipes:
                selectedCategory = nil
                
            case .fixedCategories:
                selectedCategory = fixedCategories[indexPath.row]
                
            case .customCategories:
                selectedCategory = customCategories[indexPath.row]
                
            case .specialCategories:
                if indexPath.row == 0 {
                    selectedCategory = Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(), name: "Favorites", isDefault: false, order: 0)
                } else {
                    selectedCategory = Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID(), name: "Archive", isDefault: false, order: 0)
                }
            }
        }
        
        delegate?.didSelectCategory(selectedCategory)
        
        tableView.reloadData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let customSectionIndex: Int
            if isFixedCategoriesHidden {
                customSectionIndex = 0
            } else if isSpecialCategoriesHidden {
                customSectionIndex = 1
            } else {
                customSectionIndex = Section.customCategories.rawValue
            }
            
            if indexPath.section == customSectionIndex {
                let category = customCategories[indexPath.row]
                RecipesRepository.shared.deleteCategory(category)
                customCategories.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                if selectedCategory?.id == category.id {
                    selectedCategory = nil
                    delegate?.didSelectCategory(nil)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let customSectionIndex: Int
        if isFixedCategoriesHidden {
            customSectionIndex = 0
        } else if isSpecialCategoriesHidden {
            customSectionIndex = 1
        } else {
            customSectionIndex = Section.customCategories.rawValue
        }
        return indexPath.section == customSectionIndex
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let customSectionIndex: Int
        if isFixedCategoriesHidden {
            customSectionIndex = 0
        } else if isSpecialCategoriesHidden {
            customSectionIndex = 1
        } else {
            customSectionIndex = Section.customCategories.rawValue
        }
        if indexPath.section == customSectionIndex {
            return .delete
        }
        return .none
    }
}

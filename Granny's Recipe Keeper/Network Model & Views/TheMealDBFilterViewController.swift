//
//  TheMealDBFilterViewController.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 28.01.2026.
//

import UIKit

// Структура для категорий ингредиентов
struct IngredientCategory {
    let name: String
    let ingredients: [TheMealDBIngredient]
    var isExpanded: Bool
}

// Структура для кулинарных регионов
struct CuisineRegion {
    let name: String
    let icon: String // SF Symbol
    let countries: [String] // Названия стран из API
}

class TheMealDBFilterViewController: UIViewController {
    
    weak var delegate: TheMealDBFilterViewControllerDelegate?
    
    private var areas: [AreaWithFlag] = []
    private var regions: [CuisineRegion] = []
    private var ingredientCategories: [IngredientCategory] = []
    
    private var selectedArea: AreaWithFlag?
    private var selectedRegion: CuisineRegion?
    private var selectedIngredient: TheMealDBIngredient?
    
    private var isCountriesExpanded = true
    private var isRegionsExpanded = true
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        return tableView
    }()
    
    private let countriesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    private let regionsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    
    init(areas: [AreaWithFlag], ingredients: [TheMealDBIngredient], selectedArea: AreaWithFlag?, selectedIngredient: TheMealDBIngredient?) {
        super.init(nibName: nil, bundle: nil)
        self.areas = areas
        self.selectedArea = selectedArea
        self.selectedIngredient = selectedIngredient
        
        let categorizer = TheMealDBIngredientCategorizer()
        self.ingredientCategories = categorizer.organizeIntoCategories(ingredients)
        
        self.regions = Self.createCuisineRegions()
    }
    
    private static func createCuisineRegions() -> [CuisineRegion] {
        return [
            CuisineRegion(
                name: "Mediterranean",
                icon: "🫒", // Olive
                countries: ["Italian", "Greek", "Spanish", "French"]
            ),
            CuisineRegion(
                name: "European",
                icon: "🥨", // Pretzel
                countries: ["German", "Austrian", "Swiss", "Dutch", "Belgian", "American", "Canadian"]
            ),
            CuisineRegion(
                name: "Scandinavian & Baltic",
                icon: "🐟", // Fish
                countries: ["Norwegian", "Swedish", "Danish", "Finnish", "Icelandic", "Lithuanian", "Latvian", "Estonian"]
            ),
            CuisineRegion(
                name: "Slavic",
                icon: "🥟", // Dumpling
                countries: ["Russian", "Ukrainian", "Belarusian", "Polish", "Czech", "Slovakian", "Bulgarian", "Serbian", "Croatian", "Slovenian", "Bosnian", "Montenegrin", "Macedonian"]
            ),
            CuisineRegion(
                name: "Asian",
                icon: "🍜", // Noodles
                countries: ["Chinese", "Japanese", "Korean", "Thai", "Vietnamese", "Malaysian", "Indonesian", "Filipino", "Singaporean"]
            ),
            CuisineRegion(
                name: "Indian & Pakistani",
                icon: "🍛", // Curry
                countries: ["Indian", "Pakistani", "Bangladeshi", "Nepali", "Sri Lankan"]
            ),
            CuisineRegion(
                name: "Middle Eastern",
                icon: "🧆", // Falafel
                countries: ["Lebanese", "Syrian", "Jordanian", "Israeli", "Palestinian", "Turkish", "Iranian", "Iraqi", "Saudi", "Emirati", "Qatari", "Kuwaiti", "Tunisian", "Moroccan"]
            ),
            CuisineRegion(
                name: "Latin American",
                icon: "🌮", // Taco
                countries: ["Mexican", "Brazilian", "Argentinian", "Peruvian", "Chilean", "Colombian", "Cuban", "Dominican", "Venezuelan", "Uruguayan"]
            ),
            CuisineRegion(
                name: "Caucasian",
                icon: "🍖", // Barbecue/Grilled meat
                countries: ["Georgian", "Armenian", "Azerbaijani"]
            )
        ]
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNavigationBar()
        setupTableView()
        setupCollectionViews()
        setupLayout()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.tintColor = .grannyPink
    }
    
    private func setupView() {
        view.backgroundColor = .systemGroupedBackground
        title = "Filters"
    }
    
    private func setupNavigationBar() {
        let clearButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(didTapClearButton)
        )
        
        let applyButton = UIBarButtonItem(
            image: UIImage(systemName: "checkmark"),
            style: .plain,
            target: self,
            action: #selector(didTapApplyButton)
        )
        clearButton.tintColor = .grannyPink
        applyButton.tintColor = .grannyPink
        
        navigationItem.rightBarButtonItems = [applyButton, clearButton]
        
        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(didTapCancelButton)
        )
        navigationItem.leftBarButtonItem = cancelButton
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
    
    private func setupCollectionViews() {
        countriesCollectionView.register(
            CountryCollectionViewCell.self,
            forCellWithReuseIdentifier: CountryCollectionViewCell.cellIdentifier
        )
        countriesCollectionView.dataSource = self
        countriesCollectionView.delegate = self
        
        regionsCollectionView.register(
            CountryCollectionViewCell.self,
            forCellWithReuseIdentifier: CountryCollectionViewCell.cellIdentifier
        )
        regionsCollectionView.dataSource = self
        regionsCollectionView.delegate = self
    }

    /// SFSymbol-иконки для категорий ингредиентов.
    private func symbolNameForIngredientCategory(_ categoryName: String) -> String {
        switch categoryName {
        case "Meat & Poultry":
            return "flame.fill"
        case "Fish & Seafood":
            return "fish.fill"
        case "Vegetables":
            return "carrot.fill"
        case "Grains & Legumes":
            return "takeoutbag.and.cup.and.straw"
        case "Dairy Products":
            return "carton.fill"
        case "Spices & Herbs":
            return "leaf"
        case "Other Ingredients":
            return "takeoutbag.and.cup.and.straw"
        default:
            return "takeoutbag.and.cup.and.straw"
        }
    }
    
    @objc private func didTapApplyButton() {
        delegate?.didApplyMealDBFilters(selectedArea: selectedArea, selectedRegion: selectedRegion, selectedIngredient: selectedIngredient)
        navigationController?.dismiss(animated: true)
    }
    
    @objc private func didTapCancelButton() {
        navigationController?.dismiss(animated: true)
    }
    
    @objc private func didTapClearButton() {
        selectedArea = nil
        selectedRegion = nil
        selectedIngredient = nil
        tableView.reloadData()
        
        delegate?.didApplyMealDBFilters(selectedArea: selectedArea, selectedRegion: selectedRegion, selectedIngredient: selectedIngredient)
        navigationController?.dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension TheMealDBFilterViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        // 1 секция для стран + 1 секция для регионов + N секций для категорий ингредиентов
        return 2 + ingredientCategories.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            // Секция стран
            return isCountriesExpanded ? 1 : 0
        } else if section == 1 {
            // Секция регионов
            return isRegionsExpanded ? 1 : 0
        } else {
            // Секции ингредиентов
            let categoryIndex = section - 2
            return ingredientCategories[categoryIndex].isExpanded ? 1 : 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let titleLabel = UILabel()
        titleLabel.textColor = .secondaryLabel
        
        var isExpanded = false
        var sectionTitle = ""
        
        if section == 0 {
            sectionTitle = "Filter by Country"
            isExpanded = isCountriesExpanded
        } else if section == 1 {
            sectionTitle = "Filter by Cuisine Region"
            isExpanded = isRegionsExpanded
        } else {
            let categoryIndex = section - 2
            let category = ingredientCategories[categoryIndex]
            sectionTitle = category.name
            isExpanded = category.isExpanded
        }
        
        titleLabel.text = sectionTitle
        titleLabel.font = .systemFont(ofSize: 18, weight: .heavy)
        
        headerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let chevronLabel = UILabel()
        chevronLabel.text = isExpanded ? "▼" : "▶"
        chevronLabel.font = .systemFont(ofSize: 12)
        chevronLabel.textColor = .secondaryLabel
        
        headerView.addSubview(chevronLabel)
        chevronLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            chevronLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            chevronLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapSectionHeader(_:)))
        headerView.addGestureRecognizer(tapGesture)
        headerView.tag = section
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    @objc private func didTapSectionHeader(_ gesture: UITapGestureRecognizer) {
        guard let headerView = gesture.view else { return }
        let section = headerView.tag
        
        if section == 0 {
            isCountriesExpanded.toggle()
        } else if section == 1 {
            isRegionsExpanded.toggle()
        } else {
            let categoryIndex = section - 2
            ingredientCategories[categoryIndex].isExpanded.toggle()
        }
        
        tableView.reloadSections([section], with: .automatic)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.textLabel?.text = nil
        cell.detailTextLabel?.text = nil
        cell.accessoryType = .none
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        
        if indexPath.section == 0 {
            // Добавляем collection view для стран
            cell.contentView.addSubview(countriesCollectionView)
            
            NSLayoutConstraint.activate([
                countriesCollectionView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                countriesCollectionView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                countriesCollectionView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
                countriesCollectionView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
                countriesCollectionView.heightAnchor.constraint(equalToConstant: 100)
            ])
        } else if indexPath.section == 1 {
            // Добавляем collection view для регионов
            cell.contentView.addSubview(regionsCollectionView)
            
            NSLayoutConstraint.activate([
                regionsCollectionView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                regionsCollectionView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                regionsCollectionView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
                regionsCollectionView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
                regionsCollectionView.heightAnchor.constraint(equalToConstant: 100)
            ])
        } else {
            // Добавляем collection view для категории ингредиентов
            let categoryIndex = indexPath.section - 2
            
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.minimumInteritemSpacing = 12
            layout.minimumLineSpacing = 12
            layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            
            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.backgroundColor = .clear
            collectionView.showsHorizontalScrollIndicator = false
            collectionView.tag = indexPath.section
            collectionView.register(
                IngredientCollectionViewCell.self,
                forCellWithReuseIdentifier: IngredientCollectionViewCell.cellIdentifier
            )
            collectionView.dataSource = self
            collectionView.delegate = self
            
            cell.contentView.addSubview(collectionView)
            
            NSLayoutConstraint.activate([
                collectionView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                collectionView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                collectionView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
                collectionView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
                collectionView.heightAnchor.constraint(equalToConstant: 100)
            ])
            
            // ВАЖНО: Принудительно обновляем данные сразу после создания
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension TheMealDBFilterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 116
    }
}

// MARK: - UICollectionViewDataSource
extension TheMealDBFilterViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == countriesCollectionView {
            return areas.count + 1
        } else if collectionView == regionsCollectionView {
            return regions.count // Без опции "All Regions"
        } else {
            // Ингредиенты - без опции "All", просто список ингредиентов
            let tableSection = collectionView.tag
            let categoryIndex = tableSection - 2
            guard categoryIndex >= 0 && categoryIndex < ingredientCategories.count else { return 0 }
            return ingredientCategories[categoryIndex].ingredients.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == countriesCollectionView {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CountryCollectionViewCell.cellIdentifier,
                for: indexPath
            ) as? CountryCollectionViewCell else {
                return UICollectionViewCell()
            }
            
            if indexPath.item == 0 {
                cell.configureAsAllCountries(isSelected: selectedArea == nil)
            } else {
                let area = areas[indexPath.item - 1]
                let isSelected = selectedArea?.name == area.name
                cell.configure(name: area.name, flagEmoji: area.flagEmoji, isSelected: isSelected)
            }
            
            return cell
        } else if collectionView == regionsCollectionView {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CountryCollectionViewCell.cellIdentifier,
                for: indexPath
            ) as? CountryCollectionViewCell else {
                return UICollectionViewCell()
            }
            
            // Без опции "All Regions"
            let region = regions[indexPath.item]
            let isSelected = selectedRegion?.name == region.name
            // Используем emoji иконку региона
            cell.configureWithEmoji(name: region.name, emoji: region.icon, isSelected: isSelected)
            
            return cell
        } else {
            // Ингредиенты - без опции "All"
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: IngredientCollectionViewCell.cellIdentifier,
                for: indexPath
            ) as? IngredientCollectionViewCell else {
                return UICollectionViewCell()
            }
            
            let tableSection = collectionView.tag
            let categoryIndex = tableSection - 2
            guard categoryIndex >= 0 && categoryIndex < ingredientCategories.count else {
                return cell
            }
            
            let category = ingredientCategories[categoryIndex]
            let ingredient = category.ingredients[indexPath.item]
            let ingredientName = ingredient.strIngredient ?? ""
            let isSelected = selectedIngredient?.strIngredient == ingredientName
            let symbolName = symbolNameForIngredientCategory(category.name)
            cell.configure(with: ingredientName, isSelected: isSelected, symbolNameOverride: symbolName)
            
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate
extension TheMealDBFilterViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Haptics.selection()
        if collectionView == countriesCollectionView {
            if indexPath.item == 0 {
                // При выборе "All Countries" только сбрасываем страну, но НЕ регион
                selectedArea = nil
            } else {
                let area = areas[indexPath.item - 1]
                // Toggle: если уже выбрана эта страна, снимаем выбор
                if selectedArea?.name == area.name {
                    selectedArea = nil
                } else {
                    selectedArea = area
                    selectedRegion = nil // Сбрасываем регион при выборе конкретной страны
                }
            }
            countriesCollectionView.reloadData()
            regionsCollectionView.reloadData()
        } else if collectionView == regionsCollectionView {
            // Без опции "All Regions" - сразу выбираем регион
            let region = regions[indexPath.item]
            
            // Toggle: если уже выбран этот регион, снимаем выбор
            if selectedRegion?.name == region.name {
                selectedRegion = nil
            } else {
                selectedRegion = region
                selectedArea = nil // Сбрасываем страну при выборе региона
            }
            
            countriesCollectionView.reloadData()
            regionsCollectionView.reloadData()
        } else {
            // Ингредиенты - без опции "All", сразу выбираем ингредиент
            let tableSection = collectionView.tag
            let categoryIndex = tableSection - 2
            guard categoryIndex >= 0 && categoryIndex < ingredientCategories.count else { return }
            
            let category = ingredientCategories[categoryIndex]
            let ingredient = category.ingredients[indexPath.item]
            
            // Toggle: если уже выбран этот ингредиент, снимаем выбор
            if selectedIngredient?.strIngredient == ingredient.strIngredient {
                selectedIngredient = nil
            } else {
                selectedIngredient = ingredient
            }
            
            // Обновляем все коллекции ингредиентов
            tableView.reloadData()
        }
    }
}

extension TheMealDBFilterViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 80, height: 90)
    }
}

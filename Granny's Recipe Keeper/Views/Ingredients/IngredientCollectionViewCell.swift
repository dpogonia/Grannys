//
//  IngredientCollectionViewCell.swift
//  Granny's Recipe Keeper
//
//  Created by Dmitrii Pogonia on 28.01.2026.
//

// UI ячейка для отображения ингредиентов

import UIKit

/// Ячейка для отображения ингредиента в коллекции
class IngredientCollectionViewCell: UICollectionViewCell {
    
    static let cellIdentifier = "IngredientCollectionViewCell"
    
    // UI элементы
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 4
        return view
    }()
    
    private lazy var emojiLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 32)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.textColor = .label
        return label
    }()
    
    private lazy var selectionIndicator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 2
        view.alpha = 0
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        emojiLabel.text = nil
        nameLabel.text = nil
        selectionIndicator.alpha = 0
        containerView.backgroundColor = .systemBackground
    }
    
    private func setupViews() {
        contentView.addSubview(containerView)
        containerView.addSubview(emojiLabel)
        containerView.addSubview(nameLabel)
        containerView.addSubview(selectionIndicator)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            emojiLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            emojiLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -8),
            
            selectionIndicator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            selectionIndicator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            selectionIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 4)
        ])
    }
    
    /// Конфигурация ячейки с данными ингредиента
    func configure(with ingredient: String, isSelected: Bool = false) {
        emojiLabel.text = getIngredientEmoji(for: ingredient)
        nameLabel.text = ingredient
        
        UIView.animate(withDuration: 0.2) {
            self.selectionIndicator.alpha = isSelected ? 1.0 : 0
            self.containerView.backgroundColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.1) : .systemBackground
        }
    }
    
    /// Конфигурация для "All Ingredients" ячейки
    func configureAsAllIngredients(isSelected: Bool = false) {
        emojiLabel.text = "🥘"
        nameLabel.text = "All Ingredients"
        
        UIView.animate(withDuration: 0.2) {
            self.selectionIndicator.alpha = isSelected ? 1.0 : 0
            self.containerView.backgroundColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.1) : .systemBackground
        }
    }
    
    // Маппинг ингредиентов к emoji
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func getIngredientEmoji(for ingredient: String) -> String {
        let ingredientLower = ingredient.lowercased()
        
        // Мясо
        if ingredientLower.contains("chicken") || ingredientLower.contains("poultry") { return "🍗" }
        if ingredientLower.contains("beef") || ingredientLower.contains("steak") { return "🥩" }
        if ingredientLower.contains("pork") || ingredientLower.contains("bacon") { return "🥓" }
        if ingredientLower.contains("lamb") { return "🍖" }
        
        // Морепродукты
        if ingredientLower.contains("salmon") || ingredientLower.contains("fish") { return "🐟" }
        if ingredientLower.contains("shrimp") || ingredientLower.contains("prawn") { return "🦐" }
        if ingredientLower.contains("lobster") || ingredientLower.contains("crab") { return "🦞" }
        
        // Овощи
        if ingredientLower.contains("tomato") { return "🍅" }
        if ingredientLower.contains("onion") { return "🧅" }
        if ingredientLower.contains("garlic") { return "🧄" }
        if ingredientLower.contains("carrot") { return "🥕" }
        if ingredientLower.contains("potato") { return "🥔" }
        if ingredientLower.contains("pepper") || ingredientLower.contains("capsicum") { return "🫑" }
        if ingredientLower.contains("mushroom") { return "🍄" }
        if ingredientLower.contains("broccoli") { return "🥦" }
        if ingredientLower.contains("corn") { return "🌽" }
        if ingredientLower.contains("lettuce") || ingredientLower.contains("salad") { return "🥬" }
        if ingredientLower.contains("cucumber") { return "🥒" }
        if ingredientLower.contains("avocado") { return "🥑" }
        if ingredientLower.contains("eggplant") || ingredientLower.contains("aubergine") { return "🍆" }
        
        // Фрукты
        if ingredientLower.contains("lemon") { return "🍋" }
        if ingredientLower.contains("lime") { return "🍋" }
        if ingredientLower.contains("apple") { return "🍎" }
        if ingredientLower.contains("banana") { return "🍌" }
        if ingredientLower.contains("orange") { return "🍊" }
        if ingredientLower.contains("strawberr") { return "🍓" }
        if ingredientLower.contains("mango") { return "🥭" }
        if ingredientLower.contains("pineapple") { return "🍍" }
        
        // Молочные продукты
        if ingredientLower.contains("milk") { return "🥛" }
        if ingredientLower.contains("cheese") { return "🧀" }
        if ingredientLower.contains("butter") { return "🧈" }
        if ingredientLower.contains("cream") || ingredientLower.contains("yogurt") { return "🥛" }
        if ingredientLower.contains("egg") { return "🥚" }
        
        // Хлебобулочные
        if ingredientLower.contains("bread") { return "🍞" }
        if ingredientLower.contains("flour") { return "🌾" }
        if ingredientLower.contains("pasta") || ingredientLower.contains("noodle") { return "🍝" }
        if ingredientLower.contains("rice") { return "🍚" }
        
        // Специи и приправы
        if ingredientLower.contains("chili") || ingredientLower.contains("chilli") { return "🌶️" }
        if ingredientLower.contains("ginger") { return "🫚" }
        if ingredientLower.contains("honey") { return "🍯" }
        if ingredientLower.contains("oil") || ingredientLower.contains("olive") { return "🫒" }
        if ingredientLower.contains("salt") { return "🧂" }
        
        // Сладости
        if ingredientLower.contains("chocolate") { return "🍫" }
        if ingredientLower.contains("sugar") || ingredientLower.contains("sweet") { return "🍬" }
        if ingredientLower.contains("vanilla") { return "🍦" }
        
        // Напитки
        if ingredientLower.contains("wine") { return "🍷" }
        if ingredientLower.contains("beer") { return "🍺" }
        if ingredientLower.contains("coffee") { return "☕" }
        
        // Орехи
        if ingredientLower.contains("peanut") || ingredientLower.contains("almond") || ingredientLower.contains("nut") { return "🥜" }
        
        // По умолчанию
        return "🥘"
    }
}

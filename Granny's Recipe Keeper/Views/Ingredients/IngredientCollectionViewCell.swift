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
        view.backgroundColor = .grannyPink
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
        emojiLabel.attributedText = nil
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
            // Фиксируем нижний отступ, чтобы подписи были выровнены по одной линии
            nameLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            
            selectionIndicator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            selectionIndicator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            selectionIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 4)
        ])
    }
    
    /// Конфигурация ячейки с данными ингредиента
    /// - Parameters:
    ///   - ingredient: название ингредиента
    ///   - isSelected: признак выбранного состояния
    ///   - symbolNameOverride: опциональное имя SFSymbol. Если не передано, выбирается по имени ингредиента.
    func configure(with ingredient: String, isSelected: Bool = false, symbolNameOverride: String? = nil) {
        let systemName = symbolNameOverride ?? symbolName(for: ingredient)
        emojiLabel.attributedText = makeSymbolAttachment(systemName: systemName)
        emojiLabel.text = nil
        
        nameLabel.text = ingredient
        
        UIView.animate(withDuration: 0.2) {
            self.selectionIndicator.alpha = isSelected ? 1.0 : 0
            self.containerView.backgroundColor = isSelected ? UIColor.grannyPink.withAlphaComponent(0.1) : .systemBackground
        }
    }
    
    /// Конфигурация для "All Ingredients" ячейки
    func configureAsAllIngredients(isSelected: Bool = false) {
        emojiLabel.attributedText = makeSymbolAttachment(systemName: "takeoutbag.and.cup.and.straw.fill")
        nameLabel.text = "All Ingredients"
        
        UIView.animate(withDuration: 0.2) {
            self.selectionIndicator.alpha = isSelected ? 1.0 : 0
            self.containerView.backgroundColor = isSelected ? UIColor.grannyPink.withAlphaComponent(0.1) : .systemBackground
        }
    }
    
    // Маппинг ингредиентов к SFSymbols
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func symbolName(for ingredient: String) -> String {
        let ingredientLower = ingredient.lowercased()
        
        // Мясо
        if ingredientLower.contains("chicken") || ingredientLower.contains("poultry") { return "drumstick.fill" }
        if ingredientLower.contains("beef") || ingredientLower.contains("steak") { return "fork.knife" }
        if ingredientLower.contains("pork") || ingredientLower.contains("bacon") { return "fork.knife.circle.fill" }
        if ingredientLower.contains("lamb") { return "fork.knife" }
        
        // Морепродукты
        if ingredientLower.contains("salmon") || ingredientLower.contains("fish") { return "fish.fill" }
        if ingredientLower.contains("shrimp") || ingredientLower.contains("prawn") { return "fish" }
        if ingredientLower.contains("lobster") || ingredientLower.contains("crab") { return "fish" }
        
        // Овощи
        if ingredientLower.contains("tomato") { return "leaf" }
        if ingredientLower.contains("onion") { return "circle.hexagonpath" }
        if ingredientLower.contains("garlic") { return "drop" }
        if ingredientLower.contains("carrot") { return "carrot.fill" }
        if ingredientLower.contains("potato") { return "leaf" }
        if ingredientLower.contains("pepper") || ingredientLower.contains("capsicum") { return "leaf" }
        if ingredientLower.contains("mushroom") { return "leaf" }
        if ingredientLower.contains("broccoli") { return "leaf" }
        if ingredientLower.contains("corn") { return "leaf" }
        if ingredientLower.contains("lettuce") || ingredientLower.contains("salad") { return "leaf" }
        if ingredientLower.contains("cucumber") { return "leaf" }
        if ingredientLower.contains("avocado") { return "leaf" }
        if ingredientLower.contains("eggplant") || ingredientLower.contains("aubergine") { return "leaf" }
        
        // Фрукты
        if ingredientLower.contains("lemon") { return "leaf.circle" }
        if ingredientLower.contains("lime") { return "leaf.circle" }
        if ingredientLower.contains("apple") { return "applelogo" }
        if ingredientLower.contains("banana") { return "leaf.circle" }
        if ingredientLower.contains("orange") { return "leaf.circle" }
        if ingredientLower.contains("strawberr") { return "leaf.circle" }
        if ingredientLower.contains("mango") { return "leaf.circle" }
        if ingredientLower.contains("pineapple") { return "leaf.circle" }
        
        // Молочные продукты
        if ingredientLower.contains("milk") { return "carton.fill" }
        if ingredientLower.contains("cheese") { return "circle.square" }
        if ingredientLower.contains("butter") { return "square" }
        if ingredientLower.contains("cream") || ingredientLower.contains("yogurt") { return "carton.fill" }
        if ingredientLower.contains("egg") { return "circle" }
        
        // Хлебобулочные
        if ingredientLower.contains("bread") { return "baguette" }
        if ingredientLower.contains("flour") { return "leaf" }
        if ingredientLower.contains("pasta") || ingredientLower.contains("noodle") { return "fork.knife" }
        if ingredientLower.contains("rice") { return "takeoutbag.and.cup.and.straw" }
        
        // Специи и приправы
        if ingredientLower.contains("chili") || ingredientLower.contains("chilli") { return "flame.fill" }
        if ingredientLower.contains("ginger") { return "leaf" }
        if ingredientLower.contains("honey") { return "drop.fill" }
        if ingredientLower.contains("oil") || ingredientLower.contains("olive") { return "drop.triangle" }
        if ingredientLower.contains("salt") { return "aqi.medium" }
        
        // Сладости
        if ingredientLower.contains("chocolate") { return "square.fill" }
        if ingredientLower.contains("sugar") || ingredientLower.contains("sweet") { return "cube" }
        if ingredientLower.contains("vanilla") { return "leaf" }
        
        // Напитки
        if ingredientLower.contains("wine") { return "wineglass.fill" }
        if ingredientLower.contains("beer") { return "mug.fill" }
        if ingredientLower.contains("coffee") { return "cup.and.saucer.fill" }
        
        // Орехи
        if ingredientLower.contains("peanut") || ingredientLower.contains("almond") || ingredientLower.contains("nut") { return "leaf" }
        
        // По умолчанию
        return "takeoutbag.and.cup.and.straw"
    }

    private func makeSymbolAttachment(systemName: String) -> NSAttributedString {
        let config = UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)
        let tint: UIColor = contentView.tintColor ?? .grannyPink
        guard let baseImage = UIImage(systemName: systemName, withConfiguration: config) else {
            return NSAttributedString(string: "")
        }
        let image = baseImage.withTintColor(tint, renderingMode: .alwaysOriginal)
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: -4, width: image.size.width, height: image.size.height)
        return NSAttributedString(attachment: attachment)
    }

    private func makeIcon(for ingredient: String) -> NSAttributedString {
        let name = symbolName(for: ingredient)
        return makeSymbolAttachment(systemName: name)
    }
}

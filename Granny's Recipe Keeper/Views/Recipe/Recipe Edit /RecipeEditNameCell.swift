//
//  RecipeEditNameCell.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

// MARK: - RecipeEditNameCell
// RecipeEditNameCell - это ячейка таблицы для ввода названия рецепта
// UITableViewCell - это базовый класс для ячеек таблицы
// Эта ячейка используется в экране редактирования рецепта
class RecipeEditNameCell: UITableViewCell {
    // Статическое свойство - идентификатор ячейки для переиспользования
    static let identifier = "RecipeEditNameCell"
    
    // UITextField - это поле для ввода текста (одна строка)
    // lazy var - создаётся только при первом обращении
    let textField: UITextField = {
        let textField = UITextField()
        // translatesAutoresizingMaskIntoConstraints = false - используем Auto Layout
        textField.translatesAutoresizingMaskIntoConstraints = false
        // placeholder - серый текст-подсказка, который исчезает при вводе
        textField.placeholder = "Recipe title"
        // Настраиваем шрифт: размер 17, жирный (bold)
        textField.font = .systemFont(ofSize: 17, weight: .bold)
        // clearButtonMode - показывает кнопку очистки во время редактирования
        textField.clearButtonMode = .whileEditing
        return textField
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(textField)
        selectionStyle = .none
        
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }
}

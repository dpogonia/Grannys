//
//  RecipeEditDifficultyCell.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

// MARK: - RecipeEditDifficultyCell
// RecipeEditDifficultyCell - это ячейка для выбора сложности рецепта
// Использует UISegmentedControl - это переключатель с несколькими сегментами
// Пользователь может выбрать один из вариантов: Easy, Medium или Hard
class RecipeEditDifficultyCell: UITableViewCell {
    // Идентификатор ячейки для переиспользования
    static let identifier = "RecipeEditDifficultyCell"
    
    // UISegmentedControl - это переключатель с несколькими сегментами
    // Похож на переключатель в настройках iOS (например, Wi-Fi: Вкл/Выкл)
    // Здесь три сегмента: Easy, Medium, Hard
    let segmentedControl: UISegmentedControl = {
        // Массив строк для сегментов
        let items = ["Easy", "Medium", "Hard"]
        // Создаём переключатель с этими сегментами
        let control = UISegmentedControl(items: items)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Difficulty"
        label.font = .systemFont(ofSize: 17)
        
        contentView.addSubview(label)
        contentView.addSubview(segmentedControl)
        selectionStyle = .none
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            segmentedControl.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            segmentedControl.widthAnchor.constraint(equalToConstant: 200),
            
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }
}

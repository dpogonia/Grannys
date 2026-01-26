//
//  RecipeEditInstructionsCell.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

// MARK: - RecipeEditInstructionsCell
// RecipeEditInstructionsCell - это ячейка для ввода инструкций по приготовлению
// Использует UITextView (многострочное поле ввода) вместо UITextField (одна строка)
// Потому что инструкции могут быть длинными и занимать несколько строк
class RecipeEditInstructionsCell: UITableViewCell {
    // Идентификатор ячейки для переиспользования
    static let identifier = "RecipeEditInstructionsCell"
    
    // UITextView - это многострочное поле для ввода текста
    // В отличие от UITextField, позволяет вводить несколько строк
    let textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .systemFont(ofSize: 17)
        // isScrollEnabled = false - отключаем прокрутку (ячейка растягивается по содержимому)
        textView.isScrollEnabled = false
        // textContainerInset - отступы внутри текстового поля
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        // lineFragmentPadding - убираем боковые отступы для текста
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        return textView
    }()
    
    // placeholderLabel - это метка с подсказкой "Cooking instructions"
    // Показывается, когда текстовое поле пустое
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Cooking instructions"
        label.font = .systemFont(ofSize: 17)
        // placeholderText - стандартный цвет для подсказок (серый)
        label.textColor = .placeholderText
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(textView)
        contentView.addSubview(placeholderLabel)
        selectionStyle = .none
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 8)
        ])
    }
    
    func updatePlaceholder() {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}

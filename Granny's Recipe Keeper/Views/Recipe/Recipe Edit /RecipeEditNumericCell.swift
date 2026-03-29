//
//  RecipeEditNumericCell.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 28.01.2026.
//

import UIKit

// Кастомное текстовое поле с внутренним отступом
class PaddedTextField: UITextField {
    var padding = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}

class RecipeEditNumericCell: UITableViewCell {
    static let identifier = "RecipeEditNumericCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17)
        label.textColor = .label
        return label
    }()
    
    let textField: PaddedTextField = {
        let textField = PaddedTextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textAlignment = .right
        textField.font = .systemFont(ofSize: 17)
        textField.keyboardType = .numberPad
        textField.textColor = .label
        textField.backgroundColor = .secondarySystemBackground
        textField.layer.cornerRadius = 8
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray4.cgColor
        textField.padding = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
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
        contentView.addSubview(titleLabel)
        contentView.addSubview(textField)
        selectionStyle = .none
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textField.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textField.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16),
            textField.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            textField.heightAnchor.constraint(equalToConstant: 36),
            
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }
    
    func configure(title: String, value: Int?, placeholder: String = "Tap to enter") {
        titleLabel.text = title
        
        // Настраиваем placeholder с атрибутами
        let placeholderText = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor.systemGray3,
                .font: UIFont.systemFont(ofSize: 15)
            ]
        )
        textField.attributedPlaceholder = placeholderText
        
        if let value = value, value > 0 {
            textField.text = "\(value)"
        } else {
            textField.text = nil
        }
    }
}

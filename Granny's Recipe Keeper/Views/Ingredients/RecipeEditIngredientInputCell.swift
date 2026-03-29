//
//  RecipeEditIngredientInputCell.swift
//  Granny's
//
//  Created by Cursor on 02.03.2026.
//

import UIKit

protocol RecipeEditIngredientInputCellDelegate: AnyObject {
    func ingredientInputCellDidChange(_ cell: RecipeEditIngredientInputCell, name: String, amount: String?)
}

class RecipeEditIngredientInputCell: UITableViewCell {
    static let identifier = "RecipeEditIngredientInputCell"

    weak var delegate: RecipeEditIngredientInputCellDelegate?

    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Ingredient name"
        textField.font = .systemFont(ofSize: 17)
        textField.borderStyle = .none
        textField.autocapitalizationType = .sentences
        return textField
    }()

    private let amountTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Amount"
        textField.font = .systemFont(ofSize: 17)
        textField.borderStyle = .none
        textField.textAlignment = .right
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
        selectionStyle = .none
        accessoryType = .none

        contentView.addSubview(nameTextField)
        contentView.addSubview(amountTextField)

        nameTextField.addTarget(self, action: #selector(textFieldsDidChange), for: .editingChanged)
        amountTextField.addTarget(self, action: #selector(textFieldsDidChange), for: .editingChanged)

        NSLayoutConstraint.activate([
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameTextField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            nameTextField.trailingAnchor.constraint(equalTo: amountTextField.leadingAnchor, constant: -8),

            amountTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            amountTextField.centerYAnchor.constraint(equalTo: nameTextField.centerYAnchor),
            amountTextField.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    func configure(name: String?, amount: String?) {
        nameTextField.text = name
        amountTextField.text = amount
    }

    @objc private func textFieldsDidChange() {
        let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let amount = amountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        delegate?.ingredientInputCellDidChange(self, name: name, amount: amount?.isEmpty == true ? nil : amount)
    }
}


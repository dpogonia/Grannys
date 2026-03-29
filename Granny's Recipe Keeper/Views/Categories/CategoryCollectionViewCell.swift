//
//  CategoryCollectionViewCell.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

class CategoryCollectionViewCell: UICollectionViewCell {
    static let cellIdentifier: String = "CategoryCollectionViewCell"
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        applyUnselectedStyle()
    }
    
    override var isSelected: Bool {
        didSet {
            updateSelectionState()
        }
    }
    
    func configure(with categoryName: String, isSelected: Bool = false) {
        nameLabel.text = categoryName
        self.isSelected = isSelected
    }
    
    func configureWithEmoji(with categoryName: String, emoji: String, isSelected: Bool = false) {
        nameLabel.text = categoryName
        self.isSelected = isSelected
    }
    
    private func updateSelectionState() {
        if isSelected {
            applySelectedStyle()
        } else {
            applyUnselectedStyle()
        }
    }
    
    private func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [nameLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 6
        
        contentView.addSubview(stackView)
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 0
        contentView.layer.borderColor = nil
        contentView.backgroundColor = .secondarySystemBackground
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -4),
            
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 4),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -4)
        ])
    }
    
    private func applySelectedStyle() {
        contentView.backgroundColor = .secondarySystemBackground
        
        let text = nameLabel.text ?? ""
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.grannyPink,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .underlineColor: UIColor.grannyPink
        ]
        nameLabel.attributedText = NSAttributedString(string: text, attributes: attributes)
    }
    
    private func applyUnselectedStyle() {
        contentView.backgroundColor = .secondarySystemBackground
        let text = nameLabel.attributedText?.string ?? nameLabel.text ?? ""
        nameLabel.attributedText = nil
        nameLabel.text = text
        nameLabel.textColor = .label
    }
}

//
//  CategoryCollectionViewCell.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

class CategoryCollectionViewCell: UICollectionViewCell {
    static let cellIdentifier: String = "CategoryCollectionViewCell"
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .label
        return imageView
    }()
    
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
        iconImageView.image = nil
        contentView.backgroundColor = .secondarySystemBackground
        nameLabel.textColor = .label
        iconImageView.tintColor = .label
    }
    
    override var isSelected: Bool {
        didSet {
            updateSelectionState()
        }
    }
    
    func configure(with categoryName: String, isSelected: Bool = false) {
        nameLabel.text = categoryName
        iconImageView.image = getIcon(for: categoryName)
        self.isSelected = isSelected
    }
    
    func configureWithEmoji(with categoryName: String, emoji: String, isSelected: Bool = false) {
        nameLabel.text = categoryName
        iconImageView.image = getIcon(for: categoryName)
        self.isSelected = isSelected
    }
    
    private func getIcon(for categoryName: String) -> UIImage? {
        let iconName: String
        
        switch categoryName.lowercased() {
        case "all recipes":
            iconName = "list.bullet.rectangle"
        case "breakfast":
            iconName = "sunrise.fill"
        case "dessert", "desserts":
            iconName = "birthday.cake.fill"
        case "main":
            iconName = "fork.knife"
        case "side":
            iconName = "leaf.fill"
        case "starter":
            iconName = "sparkles"
        case "vegan":
            iconName = "leaf.circle.fill"
        case "beverage", "beverages":
            iconName = "cup.and.saucer.fill"
        case "seafood":
            iconName = "fish.fill"
        case "lunch":
            iconName = "sun.max.fill"
        case "salad":
            iconName = "carrot.fill"
        case "miscellaneous":
            iconName = "star.fill"
        default:
            iconName = "circle.fill"
        }
        
        return UIImage(systemName: iconName)
    }
    
    private func updateSelectionState() {
        if isSelected {
            contentView.backgroundColor = .systemBlue
            nameLabel.textColor = .white
            iconImageView.tintColor = .white
            contentView.layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            contentView.backgroundColor = .secondarySystemBackground
            nameLabel.textColor = .label
            iconImageView.tintColor = .label
            contentView.layer.borderColor = UIColor.systemGray4.cgColor
        }
    }
    
    private func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [iconImageView, nameLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 6
        
        contentView.addSubview(stackView)
        contentView.layer.cornerRadius = 16
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.systemGray4.cgColor
        
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            nameLabel.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -4),
            
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 4),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -4)
        ])
    }
}

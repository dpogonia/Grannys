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
        imageView.tintColor = .systemBlue
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        return view
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
        iconImageView.image = nil
        nameLabel.text = nil
        containerView.backgroundColor = .secondarySystemBackground
    }
    
    override var isSelected: Bool {
        didSet {
            updateSelectionState()
        }
    }
    
    func configure(with categoryName: String, isSelected: Bool = false) {
        nameLabel.text = categoryName
        
        let iconName = iconNameForCategory(categoryName)
        iconImageView.image = UIImage(systemName: iconName)
        
        self.isSelected = isSelected
    }
    
    private func iconNameForCategory(_ category: String) -> String {
        let lowercased = category.lowercased()
        
        switch lowercased {
        case "all recipes": return "square.grid.2x2"
        case "beef", "lamb", "pork", "chicken", "goat": return "frying.pan"
        case "dessert", "desserts": return "birthday.cake"
        case "seafood": return "fish"
        case "vegetarian", "vegan": return "leaf"
        case "breakfast": return "cup.and.saucer"
        case "side", "sides", "starter", "starters", "pasta": return "circle.grid.3x3"
        case "miscellaneous": return "cooktop"
        case "soup", "soups": return "cup.and.saucer"
        case "salad", "salads": return "leaf.circle"
        case "lunch": return "fork.knife"
        case "dinner": return "moon.fill"
        case "beverages", "beverage": return "cup.and.saucer.fill"
        default: return "square.grid.2x2"
        }
    }
    
    private func updateSelectionState() {
        if isSelected {
            containerView.backgroundColor = .systemBlue.withAlphaComponent(0.2)
            iconImageView.tintColor = .systemBlue
            nameLabel.textColor = .systemBlue
            containerView.layer.borderWidth = 2
            containerView.layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            containerView.backgroundColor = .secondarySystemBackground
            iconImageView.tintColor = .label
            nameLabel.textColor = .label
            containerView.layer.borderWidth = 0
            containerView.layer.borderColor = nil
        }
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            nameLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            nameLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
}

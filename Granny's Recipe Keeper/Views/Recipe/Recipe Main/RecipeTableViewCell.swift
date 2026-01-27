//
//  RecipeTableViewCell.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

// ДЗ ТЕМА 27: Operation, OperationQueue. Использование очереди загрузки изображений

import UIKit

class RecipeTableViewCell: UITableViewCell {
    static let cellIdentifier: String = "RecipeTableViewCell"
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()
    
    private let recipeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.tintColor = .systemGray
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()
    
    private let cardContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.1
        return view
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.systemBlue.withAlphaComponent(0.1).cgColor,
            UIColor.systemPurple.withAlphaComponent(0.05).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.cornerRadius = 16
        return gradient
    }()
    
    private var currentLoadOperation: Operation?
    
    func configure(with recipe: Recipe) {
        nameLabel.text = recipe.name
        
        currentLoadOperation?.cancel()
        currentLoadOperation = nil
        
        if let image = recipe.image {
            recipeImageView.image = image
            recipeImageView.backgroundColor = .clear
        } else if let imageURL = recipe.imageURL, !imageURL.isEmpty {
            // ДОМАШНЕЕ ЗАДАНИЕ ТЕМА 27: Operation, OperationQueue.
            // Организована очередь загрузки
            // Очередь сделана в отдельном классе
            currentLoadOperation = ImageLoadQueueManager.shared.loadImage(urlString: imageURL) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let image):
                    self.recipeImageView.image = image
                    self.recipeImageView.backgroundColor = .clear
                case .failure:
                    self.recipeImageView.image = UIImage(named: "default")
                    self.recipeImageView.backgroundColor = .secondarySystemBackground
                }
                
                self.currentLoadOperation = nil
            }
        } else {
            recipeImageView.image = UIImage(named: "default")
            recipeImageView.backgroundColor = .secondarySystemBackground
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Отмена загрузки при переиспользовании ячейки
        // Организована очередь загрузки
        currentLoadOperation?.cancel()
        currentLoadOperation = nil
        
        recipeImageView.image = nil
        nameLabel.text = nil
        cardContainerView.transform = .identity
        cardContainerView.alpha = 1.0
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        UIView.animate(withDuration: 0.2) {
            if highlighted {
                self.cardContainerView.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
                self.cardContainerView.alpha = 0.8
            } else {
                self.cardContainerView.transform = .identity
                self.cardContainerView.alpha = 1.0
            }
        }
    }
    
    private func setupUI() {
        contentView.addSubview(cardContainerView)
        cardContainerView.layer.insertSublayer(gradientLayer, at: 0)
        
        cardContainerView.addSubview(recipeImageView)
        cardContainerView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            cardContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            recipeImageView.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor, constant: 12),
            recipeImageView.centerYAnchor.constraint(equalTo: cardContainerView.centerYAnchor),
            recipeImageView.widthAnchor.constraint(equalToConstant: 64),
            recipeImageView.heightAnchor.constraint(equalToConstant: 64),
            
            nameLabel.leadingAnchor.constraint(equalTo: recipeImageView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor, constant: -16),
            nameLabel.centerYAnchor.constraint(equalTo: cardContainerView.centerYAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = cardContainerView.bounds
    }
}


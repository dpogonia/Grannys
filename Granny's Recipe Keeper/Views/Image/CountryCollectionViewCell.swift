//
//  CountryCollectionViewCell.swift
//  Granny's Recipe Keeper
//
//  Created by Dmitrii Pogonia on 28.01.2026.
//

// ДОМАШНЕЕ ЗАДАНИЕ MOYA: UI для отображения данных из API

import UIKit

/// ДОМАШНЕЕ ЗАДАНИЕ MOYA: Реализовано отображение данных - 40 баллов
/// Ячейка для отображения страны в коллекции
class CountryCollectionViewCell: UICollectionViewCell {
    
    static let cellIdentifier = "CountryCollectionViewCell"
    
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
    
    private lazy var flagLabel: UILabel = {
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
        view.backgroundColor = .systemBlue
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
        flagLabel.text = nil
        nameLabel.text = nil
        selectionIndicator.alpha = 0
        containerView.backgroundColor = .systemBackground
    }
    
    private func setupViews() {
        contentView.addSubview(containerView)
        containerView.addSubview(flagLabel)
        containerView.addSubview(nameLabel)
        containerView.addSubview(selectionIndicator)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            flagLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            flagLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: flagLabel.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -8),
            
            selectionIndicator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            selectionIndicator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            selectionIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 4)
        ])
    }
    
    // ДОМАШНЕЕ ЗАДАНИЕ MOYA: Реализовано отображение данных - 40 баллов
    /// Конфигурация для "All Countries" ячейки
    func configureAsAllCountries(isSelected: Bool = false) {
        flagLabel.text = "🌍"
        nameLabel.text = "All Countries"
        
        UIView.animate(withDuration: 0.2) {
            self.selectionIndicator.alpha = isSelected ? 1.0 : 0
            self.containerView.backgroundColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.1) : .systemBackground
        }
    }
    
    /// Конфигурация с названием и флагом (универсальный метод)
    func configure(name: String, flagEmoji: String, isSelected: Bool = false) {
        self.flagLabel.text = flagEmoji
        self.nameLabel.text = name
        
        UIView.animate(withDuration: 0.2) {
            self.selectionIndicator.alpha = isSelected ? 1.0 : 0
            self.containerView.backgroundColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.1) : .systemBackground
        }
    }
    
    /// Конфигурация для регионов с emoji иконкой
    func configureWithEmoji(name: String, emoji: String, isSelected: Bool = false) {
        self.flagLabel.text = emoji
        self.nameLabel.text = name
        
        UIView.animate(withDuration: 0.2) {
            self.selectionIndicator.alpha = isSelected ? 1.0 : 0
            self.containerView.backgroundColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.1) : .systemBackground
        }
    }
}

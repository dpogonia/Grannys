//
//  RecipeEditTagsCell.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

// MARK: - LeftAlignedFlowLayout
// LeftAlignedFlowLayout - это кастомный layout для коллекции тегов
// Layout определяет, как элементы располагаются в коллекции
// Этот layout выравнивает элементы по левому краю (как текст в текстовом редакторе)
// В отличие от стандартного FlowLayout, который центрирует элементы
class LeftAlignedFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        
        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0
        
        attributes?.forEach { layoutAttribute in
            if layoutAttribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }
            
            layoutAttribute.frame.origin.x = leftMargin
            
            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            maxY = max(layoutAttribute.frame.maxY, maxY)
        }
        
        return attributes
    }
}

// MARK: - RecipeEditTagsCell
// RecipeEditTagsCell - это ячейка для отображения тегов рецепта
// Использует UICollectionView для показа тегов в виде "чипсов" (маленьких прямоугольников)
// Теги можно выбирать, нажимая на них (например, "вегетарианский", "без глютена")
class RecipeEditTagsCell: UITableViewCell {
    // Идентификатор ячейки для переиспользования
    static let identifier = "RecipeEditTagsCell"
    
    // UICollectionView - это коллекция элементов (как таблица, но с более гибкой компоновкой)
    // Здесь используется для отображения тегов в виде сетки
    let collectionView: UICollectionView = {
        // Создаём кастомный layout для выравнивания по левому краю
        let layout = LeftAlignedFlowLayout()
        // minimumInteritemSpacing - минимальное расстояние между элементами в одной строке (4 пикселя)
        layout.minimumInteritemSpacing = 4
        // minimumLineSpacing - минимальное расстояние между строками (6 пикселей)
        layout.minimumLineSpacing = 6
        // sectionInset - отступы вокруг всей коллекции
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        // Создаём коллекцию с нашим layout
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        // Регистрируем тип ячейки для тегов (TagCollectionViewCell)
        collectionView.register(TagCollectionViewCell.self, forCellWithReuseIdentifier: "TagCell")
        return collectionView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(collectionView)
        selectionStyle = .none
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            collectionView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }
}

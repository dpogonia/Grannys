//
//  TagCollectionViewCell.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

class TagCollectionViewCell: UICollectionViewCell {
    static let identifier = "TagCell"
    
    private let tagLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        contentView.addSubview(tagLabel)
        contentView.layer.cornerRadius = 16
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.systemGray4.cgColor
        
        NSLayoutConstraint.activate([
            tagLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            tagLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            tagLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            tagLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with tag: String, isSelected: Bool) {
        tagLabel.text = tag
        
        if isSelected {
            contentView.backgroundColor = .systemBlue
            tagLabel.textColor = .white
            contentView.layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            contentView.backgroundColor = .secondarySystemBackground
            tagLabel.textColor = .label
            contentView.layer.borderColor = UIColor.systemGray4.cgColor
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        tagLabel.text = nil
        contentView.backgroundColor = .secondarySystemBackground
        tagLabel.textColor = .label
    }
}

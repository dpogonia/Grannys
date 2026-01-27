//
//  RecipeEditPhotoCell.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

class RecipeEditPhotoCell: UITableViewCell {
    static let identifier = "RecipeEditPhotoCell"
    
    let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.layer.cornerRadius = 8
        imageView.isHidden = true
        return imageView
    }()
    
    let addPhotoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "default")
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var imageHeightConstraint: NSLayoutConstraint!
    private var buttonTopToImageConstraint: NSLayoutConstraint!
    private var buttonTopToContentViewConstraint: NSLayoutConstraint!
    
    private func setupUI() {
        contentView.addSubview(photoImageView)
        contentView.addSubview(addPhotoImageView)
        selectionStyle = .none
        
        imageHeightConstraint = photoImageView.heightAnchor.constraint(equalToConstant: 0)
        buttonTopToImageConstraint = addPhotoImageView.topAnchor.constraint(equalTo: photoImageView.bottomAnchor, constant: 8)
        buttonTopToContentViewConstraint = addPhotoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8)
        
        let contentHeightConstraint = contentView.heightAnchor.constraint(equalToConstant: 104)
        contentHeightConstraint.priority = UILayoutPriority(999)
        
        NSLayoutConstraint.activate([
            photoImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            photoImageView.widthAnchor.constraint(equalToConstant: 88),
            imageHeightConstraint,
            
            addPhotoImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            addPhotoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            addPhotoImageView.widthAnchor.constraint(equalToConstant: 88),
            addPhotoImageView.heightAnchor.constraint(equalToConstant: 88),
            
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 104),
            contentHeightConstraint
        ])
    }
    
    func configure(hasImage: Bool) {
        if hasImage {
            photoImageView.isHidden = false
            imageHeightConstraint.constant = 88
            addPhotoImageView.isHidden = true
            photoImageView.isUserInteractionEnabled = true
            buttonTopToContentViewConstraint.isActive = false
            buttonTopToImageConstraint.isActive = false
        } else {
            photoImageView.isHidden = true
            imageHeightConstraint.constant = 0
            addPhotoImageView.isHidden = false
            photoImageView.isUserInteractionEnabled = false
            buttonTopToImageConstraint.isActive = false
            buttonTopToContentViewConstraint.isActive = true
        }
    }
}

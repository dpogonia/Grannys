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
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.layer.cornerRadius = 8
        imageView.isHidden = true
        return imageView
    }()
    
    let addPhotoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = nil
        imageView.contentMode = .center
        imageView.backgroundColor = .clear
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private let placeholderIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let plusBadgeView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray3
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    private let plusBadgeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "plus")
        imageView.tintColor = .systemBackground
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private var dashedBorderLayer: CAShapeLayer?
    
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateDashedBorder()
    }
    
    private func setupUI() {
        contentView.addSubview(photoImageView)
        contentView.addSubview(addPhotoImageView)
        addPhotoImageView.addSubview(placeholderIconImageView)
        addPhotoImageView.addSubview(plusBadgeView)
        plusBadgeView.addSubview(plusBadgeImageView)
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
        
        NSLayoutConstraint.activate([
            placeholderIconImageView.topAnchor.constraint(equalTo: addPhotoImageView.topAnchor, constant: 12),
            placeholderIconImageView.leadingAnchor.constraint(equalTo: addPhotoImageView.leadingAnchor, constant: 12),
            placeholderIconImageView.trailingAnchor.constraint(equalTo: addPhotoImageView.trailingAnchor, constant: -12),
            placeholderIconImageView.bottomAnchor.constraint(equalTo: addPhotoImageView.bottomAnchor, constant: -12),
            
            plusBadgeView.trailingAnchor.constraint(equalTo: addPhotoImageView.trailingAnchor, constant: -6),
            plusBadgeView.bottomAnchor.constraint(equalTo: addPhotoImageView.bottomAnchor, constant: -6),
            plusBadgeView.widthAnchor.constraint(equalToConstant: 20),
            plusBadgeView.heightAnchor.constraint(equalToConstant: 20),
            
            plusBadgeImageView.centerXAnchor.constraint(equalTo: plusBadgeView.centerXAnchor),
            plusBadgeImageView.centerYAnchor.constraint(equalTo: plusBadgeView.centerYAnchor),
            plusBadgeImageView.widthAnchor.constraint(equalToConstant: 10),
            plusBadgeImageView.heightAnchor.constraint(equalToConstant: 10)
        ])
        
        // Значок "+" больше не используем визуально
        plusBadgeView.isHidden = true
        plusBadgeImageView.isHidden = true
    }
    
    private func updateDashedBorder() {
        dashedBorderLayer?.removeFromSuperlayer()
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor.systemGray4.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineDashPattern = [6, 3]
        shapeLayer.lineWidth = 1
        shapeLayer.path = UIBezierPath(roundedRect: addPhotoImageView.bounds, cornerRadius: 8).cgPath
        
        addPhotoImageView.layer.addSublayer(shapeLayer)
        dashedBorderLayer = shapeLayer
    }
    
    func configure(hasImage: Bool) {
        if hasImage {
            photoImageView.isHidden = false
            imageHeightConstraint.constant = 88
            addPhotoImageView.isHidden = true
            placeholderIconImageView.isHidden = true
            photoImageView.isUserInteractionEnabled = true
        } else {
            photoImageView.isHidden = true
            imageHeightConstraint.constant = 0
            addPhotoImageView.isHidden = false
            placeholderIconImageView.isHidden = false
            photoImageView.isUserInteractionEnabled = false
        }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
}

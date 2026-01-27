//
//  SkeletonLoadingCell.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

class SkeletonLoadingCell: UITableViewCell {
    static let cellIdentifier: String = "SkeletonLoadingCell"
    
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
    
    private let imageSkeletonView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let titleSkeletonView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let subtitleSkeletonView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let shimmerLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.systemGray5.cgColor,
            UIColor.systemGray4.cgColor,
            UIColor.systemGray5.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.locations = [0, 0.5, 1]
        return gradient
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        startShimmerAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        startShimmerAnimation()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(cardContainerView)
        cardContainerView.addSubview(imageSkeletonView)
        cardContainerView.addSubview(titleSkeletonView)
        cardContainerView.addSubview(subtitleSkeletonView)
        
        NSLayoutConstraint.activate([
            cardContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            imageSkeletonView.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor, constant: 12),
            imageSkeletonView.centerYAnchor.constraint(equalTo: cardContainerView.centerYAnchor),
            imageSkeletonView.widthAnchor.constraint(equalToConstant: 64),
            imageSkeletonView.heightAnchor.constraint(equalToConstant: 64),
            
            titleSkeletonView.leadingAnchor.constraint(equalTo: imageSkeletonView.trailingAnchor, constant: 16),
            titleSkeletonView.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor, constant: -16),
            titleSkeletonView.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 24),
            titleSkeletonView.heightAnchor.constraint(equalToConstant: 16),
            
            subtitleSkeletonView.leadingAnchor.constraint(equalTo: imageSkeletonView.trailingAnchor, constant: 16),
            subtitleSkeletonView.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor, constant: -80),
            subtitleSkeletonView.topAnchor.constraint(equalTo: titleSkeletonView.bottomAnchor, constant: 12),
            subtitleSkeletonView.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shimmerLayer.frame = cardContainerView.bounds
    }
    
    private func startShimmerAnimation() {
        cardContainerView.layer.insertSublayer(shimmerLayer, at: 0)
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 1.5
        animation.repeatCount = .greatestFiniteMagnitude
        shimmerLayer.add(animation, forKey: "shimmer")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        shimmerLayer.removeAnimation(forKey: "shimmer")
        startShimmerAnimation()
    }
}

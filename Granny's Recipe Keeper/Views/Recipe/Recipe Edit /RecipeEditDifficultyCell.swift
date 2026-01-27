//
//  RecipeEditDifficultyCell.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 17.12.2025.
//

import UIKit

class RecipeEditDifficultyCell: UITableViewCell {
    static let identifier = "RecipeEditDifficultyCell"
    
    let segmentedControl: UISegmentedControl = {
        let items = ["Easy", "Medium", "Hard"]
        let control = UISegmentedControl(items: items)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Difficulty"
        label.font = .systemFont(ofSize: 17)
        
        contentView.addSubview(label)
        contentView.addSubview(segmentedControl)
        selectionStyle = .none
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            segmentedControl.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            segmentedControl.widthAnchor.constraint(equalToConstant: 200),
            
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }
}

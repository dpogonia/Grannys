//
//  FilterProtocols.swift
//  Granny's Recipe Keeper
//
//  Protocols separated from implementation
//

import UIKit

protocol FilterViewControllerDelegate: AnyObject {
    func didApplyFilters(selectedTags: Set<String>, selectedDifficulty: String?, selectedIngredients: Set<String>)
}

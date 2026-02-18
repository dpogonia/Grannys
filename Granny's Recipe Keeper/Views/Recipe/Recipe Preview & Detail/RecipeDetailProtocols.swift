//
//  RecipeDetailProtocols.swift
//  Granny's Recipe Keeper
//
//  Protocols separated from implementation
//

import UIKit

protocol RecipeDetailViewControllerDelegate: AnyObject {
    func didUpdateRecipe()
    func didDeleteRecipe()
}

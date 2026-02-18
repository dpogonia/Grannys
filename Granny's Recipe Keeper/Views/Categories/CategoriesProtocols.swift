//
//  CategoriesProtocols.swift
//  Granny's Recipe Keeper
//
//  Protocols separated from implementation
//

import UIKit

protocol CategoriesViewControllerDelegate: AnyObject {
    func didSelectCategory(_ category: Category?)
}

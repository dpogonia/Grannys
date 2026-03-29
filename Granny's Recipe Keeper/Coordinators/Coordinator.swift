//
//  RecipeCommand.swift
//  Granny's
//
//  Created by Dmitrii Pogonia on 28.03.2026.
//

import UIKit

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    func start()
}


//
//  TheMealDBFilterProtocols.swift
//  Granny's Recipe Keeper
//
//

import Foundation

protocol TheMealDBFilterViewControllerDelegate: AnyObject {
    func didApplyMealDBFilters(
        selectedArea: AreaWithFlag?,
        selectedRegion: CuisineRegion?,
        selectedIngredient: TheMealDBIngredient?
    )
}


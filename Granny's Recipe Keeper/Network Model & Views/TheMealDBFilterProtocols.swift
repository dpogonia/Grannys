//
//  TheMealDBFilterProtocols.swift
//  Granny's Recipe Keeper
//
//  Protocols separated from implementation
//

import Foundation

protocol TheMealDBFilterViewControllerDelegate: AnyObject {
    func didApplyMealDBFilters(
        selectedArea: AreaWithFlag?,
        selectedRegion: CuisineRegion?,
        selectedIngredient: TheMealDBIngredient?
    )
}


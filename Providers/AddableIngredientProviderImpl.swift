//
//  AddableIngredientProviderImpl.swift
//  Providers
//
//  Created by Ivan Schuetz on 20/01/2017.
//
//

import UIKit
import RealmSwift

public struct AddableIngredients {
    public let results: Results<Ingredient> // todo rename in ingredients!
    public let brands: [String: [String]] // ingredient uuid - brands (which are associated with products with the same name as the ingredient product)
    public let units: Results<Unit> // all units in the app
    public let baseQuantities: RealmSwift.List<BaseQuantity> // for now this is all base quantities that exist in all products
}

class AddableIngredientProviderImpl: AddableIngredientProvider {

    // Fetches all data needed by add recipe to list use case (ingredients, brands, units and bases)
    func addableIngredients(recipe: Recipe, handler: @escaping (ProviderResult<AddableIngredients>) -> Void) {
        
        Prov.ingredientProvider.ingredients(recipe: recipe, sortBy: .alphabetic) {ingredientsResult in
            guard let ingredients = ingredientsResult.sucessResult else {
                logger.e("No ingredients")
                handler(ProviderResult(status: ingredientsResult.status))
                return
            }
            
            Prov.brandProvider.brands(ingredients: ingredients) {brandsResult in
                guard let ingredientsWithBrands = brandsResult.sucessResult else {
                    logger.e("No ingredientsWithBrands")
                    handler(ProviderResult(status: brandsResult.status))
                    return
                }
                
                // This is used to add ingredients to a shopping list, so we are only interested in buyable units
                Prov.unitProvider.units(buyable: true, {allUnitsResult in
                    guard let allUnits = allUnitsResult.sucessResult else {
                        logger.e("No units")
                        handler(ProviderResult(status: allUnitsResult.status))
                        return
                    }
                    
                    Prov.unitProvider.baseQuantities {baseQuantitiesResult in
                        guard let allBaseQuantities = baseQuantitiesResult.sucessResult else {
                            logger.e("No base quantities")
                            handler(ProviderResult(status: baseQuantitiesResult.status))
                            return
                        }
                        
                        let addableIngredients = AddableIngredients(results: ingredients, brands: ingredientsWithBrands, units: allUnits, baseQuantities: allBaseQuantities)
                        handler(ProviderResult(status: .success, sucessResult: addableIngredients))
                    }
                })
            }
        }
    }
}

//
//  AddableIngredientProviderImpl.swift
//  Providers
//
//  Created by Ivan Schuetz on 20/01/2017.
//
//

import UIKit
import RealmSwift
import QorumLogs

public struct AddableIngredients {
    public let results: Results<Ingredient>
    public let brands: [String: [String]] // ingredient uuid - brands (which are associated with products with the same name as the ingredient product)
    public let units: [ProductUnit] // for now this is all the units that exist in all products
    public let baseQuantities: [String] // for now this is all base quantities that exist in all products
}


class AddableIngredientProviderImpl: AddableIngredientProvider {
 
    func addableIngredients(recipe: Recipe, handler: @escaping (ProviderResult<AddableIngredients>) -> Void) {
        
        Prov.ingredientProvider.ingredients(recipe: recipe, sortBy: .alphabetic) {ingredientsResult in
            guard let ingredients = ingredientsResult.sucessResult else {
                QL4("No ingredients")
                handler(ProviderResult(status: ingredientsResult.status))
                return
            }
            
            Prov.brandProvider.brands(ingredients: ingredients) {brandsResult in
                guard let ingredientsWithBrands = brandsResult.sucessResult else {
                    QL4("No ingredientsWithBrands")
                    handler(ProviderResult(status: brandsResult.status))
                    return
                }
                
                Prov.productProvider.allUnits({ allUnitsResult in
                    guard let allUnits = allUnitsResult.sucessResult else {
                        QL4("No units")
                        handler(ProviderResult(status: allUnitsResult.status))
                        return
                    }
                    
                    Prov.productProvider.allBaseQuantities({allBaseQuantitiesResult in
                        guard let allBaseQuantities = allBaseQuantitiesResult.sucessResult else {
                            QL4("No base quantities")
                            handler(ProviderResult(status: allBaseQuantitiesResult.status))
                            return
                        }
                        
                        let addableIngredients = AddableIngredients(results: ingredients, brands: ingredientsWithBrands, units: allUnits, baseQuantities: allBaseQuantities)
                        handler(ProviderResult(status: .success, sucessResult: addableIngredients))
                    })
                })
            }
        }
    }
}

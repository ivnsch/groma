//
//  IngredientProviderImpl.swift
//  Providers
//
//  Created by Ivan Schuetz on 17/01/2017.
//
//

import UIKit
import RealmSwift
import QorumLogs

class IngredientProviderImpl: IngredientProvider {
    
    func ingredients(recipe: Recipe, sortBy: InventorySortBy, _ handler: @escaping (ProviderResult<Results<Ingredient>>) -> Void) {
        DBProv.ingredientProvider.ingredients(recipe: recipe, sortBy: sortBy) {resultsMaybe in
            if let results = resultsMaybe {
                handler(ProviderResult(status: .success, sucessResult: results))
            } else {
                QL4("Couldn't retrieve ingredients")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func add(_ quantifiableProduct: QuantifiableProduct, quantity: Int, recipe: Recipe, ingredients: Results<Ingredient>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<(ingredient: Ingredient, isNew: Bool)>) -> Void) {
        DBProv.ingredientProvider.add(quantifiableProduct, quantity: quantity, recipe: recipe, ingredients: ingredients, notificationToken: notificationToken) {ingredientMaybe in
            if let ingredient = ingredientMaybe {
                handler(ProviderResult(status: .success, sucessResult: ingredient))
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func increment(_ ingredient: Ingredient, quantity: Int, notificationToken: NotificationToken, realm: Realm, _ handler: @escaping (ProviderResult<Int>) -> Void) {
        DBProv.ingredientProvider.increment(ingredient, quantity: quantity, notificationToken: notificationToken, realm: realm) {quantityMaybe in
            if let quantity = quantityMaybe {
                handler(ProviderResult(status: .success, sucessResult: quantity))
            } else {
                QL4("Couldn't increment")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    // Used by input form (retrives quantifiable product, creates ingredient)
    func add(_ input: IngredientInput, recipe: Recipe, ingredients: Results<Ingredient>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        
        addOrUpdateProduct(input: input, notificationToken: notificationToken) {productResult in
            
            if let product = productResult.sucessResult {
                self.add(product, quantity: input.quantity, recipe: recipe, ingredients: ingredients, notificationToken: notificationToken) {result in
                    handler(ProviderResult(status: result.status))
                }
                
            } else {
                QL4("Error fetching product: \(productResult.status)")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func update(_ ingredient: Ingredient, input: IngredientInput, ingredients: Results<Ingredient>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<(ingredient: Ingredient, replaced: Bool)>) -> Void) {
        
        // Remove a (different) possible already existing item with same unique (name+brand) in the same list (imagine I'm editing an item A and my new inputs correspond to unique from another item B which is in the list how do we handle this? we could alert the user but this may be a bit of an overkill, at least for now, so we simply replace (i.e. delete) the other item. We return the deleted item to be able to delete it from the table view. Note that we exclude the editing item from the delete - since this is not being executed in a transaction it's not safe to just delete it to re-add it in subsequent steps.
        let quantifiableProductUnique = QuantifiableProductUnique(name: input.name, brand: input.brand, unit: input.unit, baseQuantity: input.baseQuantity)
        DBProv.ingredientProvider.deletePossibleIngredient(quantifiableProductUnique: quantifiableProductUnique, recipe: ingredient.recipe, notUuid: ingredient.uuid) {foundAndDeletedIngredient in
            
            self.addOrUpdateProduct(input: input, notificationToken: notificationToken) {productResult in
                
                if let product = productResult.sucessResult {
                    let updatedIngredient = ingredient.copy(quantity: input.quantity, product: product)
                    
                    // Now do plain update of the item
                    DBProv.ingredientProvider.update(ingredient, input: input, ingredients: ingredients, notificationToken: notificationToken) {success in
                        if success {
                            handler(ProviderResult(status: .success, sucessResult: (ingredient: updatedIngredient, replaced: foundAndDeletedIngredient)))
                        } else {
                            QL4("Error updating ingredient: \(productResult)")
                            handler(ProviderResult(status: productResult.status))
                        }
                    }
                    
                    //                    self?.update(updatedIngredient) {result in
                    //                        if result.success {
                    //                            handler(ProviderResult(status: .success, sucessResult: (recipe: updatedIngredient, replaced: foundAndDeletedIngredient)))
                    //                        } else {
                    //                            QL4("Error updating ingredient: \(result)")
                    //                            handler(ProviderResult(status: result.status))
                    //                        }
                    //                    }
                    
                    
                } else {
                    QL4("Error fetching product: \(productResult.status)")
                    handler(ProviderResult(status: .databaseUnknown))
                }
                
            }
        }
    }
    
    func delete(_ ingredient: Ingredient, ingredients: Results<Ingredient>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.ingredientProvider.delete(ingredient, ingredients: ingredients, notificationToken: notificationToken) {success in
            handler(ProviderResult(status: success ? .success : .databaseUnknown))
        }
    }
    
    // MARK: - Private
    
    /// Helper to add/retrieve/update quantifiable product to be used for add/update ingredient
    /// NOTE: notificationToken not used here - should it? TODO!!!!!!!!!!!!!!!!!!!
    fileprivate func addOrUpdateProduct(input: IngredientInput, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<QuantifiableProduct>) -> Void) {
        
        let prototype = ProductPrototype(name: input.name, category: input.category, categoryColor: input.categoryColor, brand: input.brand, baseQuantity: input.baseQuantity, unit: input.unit)
        // This will update the quantifiable product references with same algorithm for all product pointing items in the app
        Prov.productProvider.mergeOrCreateProduct(prototype: prototype, updateCategory: false, updateItem: false) {(result: ProviderResult<QuantifiableProduct>) in
            
            if let product = result.sucessResult {
                handler(ProviderResult(status: .success, sucessResult: product))
                
            } else {
                QL4("Error fetching product: \(result.status)")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
}

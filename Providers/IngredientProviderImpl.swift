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
    
    func add(_ quickAddInput: QuickAddIngredientInput, recipe: Recipe, ingredients: Results<Ingredient>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<(ingredient: Ingredient, isNew: Bool)>) -> Void) {
        DBProv.ingredientProvider.add(quickAddInput, recipe: recipe, ingredients: ingredients, notificationToken: notificationToken) {ingredientMaybe in
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
        addOrUpdateItem(input: input, notificationToken: notificationToken) {itemResult in
            
            if let item = itemResult.sucessResult {
                
                // TODO better name for quickadd item - PseudoIngredient, IngredientInputWithDependencies or something
                let quickAddItem = QuickAddIngredientInput(item: item, quantity: input.quantity, unit: input.unit)
                
                self.add(quickAddItem, recipe: recipe, ingredients: ingredients, notificationToken: notificationToken) {result in
                    handler(ProviderResult(status: result.status))
                }
                
            } else {
                QL4("Error fetching item: \(itemResult.status)")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func update(_ ingredient: Ingredient, input: IngredientInput, ingredients: Results<Ingredient>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<(ingredient: Ingredient, replaced: Bool)>) -> Void) {
        
        // Remove a (different) possible already existing item with same unique (name+brand) in the same list (imagine I'm editing an item A and my new inputs correspond to unique from another item B which is in the list how do we handle this? we could alert the user but this may be a bit of an overkill, at least for now, so we simply replace (i.e. delete) the other item. We return the deleted item to be able to delete it from the table view. Note that we exclude the editing item from the delete - since this is not being executed in a transaction it's not safe to just delete it to re-add it in subsequent steps.
        DBProv.ingredientProvider.deletePossibleIngredient(itemName: ingredient.item.name, recipe: ingredient.recipe, notUuid: ingredient.uuid) {foundAndDeletedIngredient in
            
            self.addOrUpdateItem(input: input, notificationToken: notificationToken) {itemResult in
                
                if let item = itemResult.sucessResult {
                    let updatedIngredient = ingredient.copy(quantity: input.quantity, item: item)
                    
                    // Now do plain update of the item
                    DBProv.ingredientProvider.update(ingredient, input: input, ingredients: ingredients, notificationToken: notificationToken) {success in
                        if success {
                            handler(ProviderResult(status: .success, sucessResult: (ingredient: updatedIngredient, replaced: foundAndDeletedIngredient)))
                        } else {
                            QL4("Error updating ingredient: \(itemResult)")
                            handler(ProviderResult(status: itemResult.status))
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
                    QL4("Error fetching product: \(itemResult.status)")
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
    
    
    /// Helper to add/retrieve/update quantifiable product to be used for add/update ingredient
    /// NOTE: notificationToken not used here - should it? TODO!!!!!!!!!!!!!!!!!!!
    fileprivate func addOrUpdateItem(input: IngredientInput, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Item>) -> Void) {
        
        let itemInput = ItemInput(name: input.name, categoryName: input.category, categoryColor: input.categoryColor)
        
        // TODO!!!!!!!!!!!!!!!! review updateCategory parameter (updates color) here and for product - for product it's false, why?
        switch DBProv.itemProvider.mergeOrCreateItemSync(itemInput: itemInput, updateCategory: true) {
        case .ok(let item): handler(ProviderResult(status: .success, sucessResult: item))
        case .err(let error):
            QL4("Error fetching item: \(error)")
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
}

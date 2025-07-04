//
//  IngredientProviderImpl.swift
//  Providers
//
//  Created by Ivan Schuetz on 17/01/2017.
//
//

import UIKit
import RealmSwift


class IngredientProviderImpl: IngredientProvider {
    
    func ingredients(recipe: Recipe, sortBy: InventorySortBy, _ handler: @escaping (ProviderResult<Results<Ingredient>>) -> Void) {
        DBProv.ingredientProvider.ingredients(recipe: recipe, sortBy: sortBy) {resultsMaybe in
            if let results = resultsMaybe {
                handler(ProviderResult(status: .success, sucessResult: results))
            } else {
                logger.e("Couldn't retrieve ingredients")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func add(_ quickAddInput: QuickAddIngredientInput, recipe: Recipe, ingredients: Results<Ingredient>, notificationTokens: [NotificationToken], _ handler: @escaping (ProviderResult<(ingredient: Ingredient, isNew: Bool)>) -> Void) {
        DBProv.ingredientProvider.add(quickAddInput, recipe: recipe, ingredients: ingredients, notificationTokens: notificationTokens) {ingredientMaybe in
            if let ingredient = ingredientMaybe {
                handler(ProviderResult(status: .success, sucessResult: ingredient))
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func increment(_ ingredient: Ingredient, quantity: Float, notificationTokens: [NotificationToken], realm: Realm, _ handler: @escaping (ProviderResult<Float>) -> Void) {
        DBProv.ingredientProvider.increment(ingredient, quantity: quantity, notificationTokens: notificationTokens, realm: realm) {quantityMaybe in
            if let quantity = quantityMaybe {
                handler(ProviderResult(status: .success, sucessResult: quantity))
            } else {
                logger.e("Couldn't increment")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    // TODO Fraction etc.
    // Used by input form (retrives quantifiable product, creates ingredient)
    func add(_ input: IngredientInput, recipe: Recipe, ingredients: Results<Ingredient>, notificationTokens: [NotificationToken], _ handler: @escaping (ProviderResult<(ingredient: Ingredient, isNew: Bool)>) -> Void) {
        addOrUpdateItem(input: input, notificationTokens: notificationTokens, doTransaction: true) {itemResult in
            
            if let item = itemResult.sucessResult {
                
                // TODO better name for quickadd item - PseudoIngredient, IngredientInputWithDependencies or something
                let quickAddItem = QuickAddIngredientInput(item: item.0, quantity: input.quantity, unit: input.unit, fraction: Fraction.zero)
                
                self.add(quickAddItem, recipe: recipe, ingredients: ingredients, notificationTokens: notificationTokens) {result in
                    handler(result)
                }
                
            } else {
                logger.e("Error fetching item: \(itemResult.status)")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func add(_ ingredients: [Ingredient], _ handler: @escaping (ProviderResult<Any>) -> Void) {
        if DBProv.ingredientProvider.add(ingredients: ingredients) {
            handler(ProviderResult(status: .success))
        } else {
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
    
    func update(_ ingredient: Ingredient, input: IngredientInput, ingredients: Results<Ingredient>, notificationTokens: [NotificationToken], _ handler: @escaping (ProviderResult<(ingredient: Ingredient, replaced: Bool)>) -> Void) {
        
        // Remove a (different) possible already existing item with same unique (name+brand) in the same list (imagine I'm editing an item A and my new inputs correspond to unique from another item B which is in the list how do we handle this? we could alert the user but this may be a bit of an overkill, at least for now, so we simply replace (i.e. delete) the other item. We return the deleted item to be able to delete it from the table view. Note that we exclude the editing item from the delete - since this is not being executed in a transaction it's not safe to just delete it to re-add it in subsequent steps.
        DBProv.ingredientProvider.deletePossibleIngredient(itemName: ingredient.item.name, recipe: ingredient.recipe, notUuid: ingredient.uuid) {foundAndDeletedIngredient in
            
            self.addOrUpdateItem(input: input, notificationTokens: notificationTokens, doTransaction: true) { itemResult in
                
                if let item = itemResult.sucessResult {

                    DBProv.ingredientProvider.update(ingredient, input: input, item: item.0, ingredients: ingredients, notificationTokens: notificationTokens) { success in
                        if success {
                            handler(ProviderResult(status: .success, sucessResult: (ingredient: ingredient, replaced: foundAndDeletedIngredient)))
                        } else {
                            logger.e("Error updating ingredient: \(itemResult)")
                            handler(ProviderResult(status: itemResult.status))
                        }
                    }
                    
                } else {
                    logger.e("Error retrieving item: \(itemResult.status)")
                    handler(ProviderResult(status: .databaseUnknown))
                }
            }
        }
    }
    
    func updateLastProductInputs(ingredientModels: [AddRecipeIngredientModel], _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.ingredientProvider.updateLastProductInputs(ingredientModels: ingredientModels) {success in
            handler(ProviderResult(status: success ? .success : .databaseUnknown))
        }
    }
    
    func delete(_ ingredient: Ingredient, ingredients: Results<Ingredient>, notificationTokens: [NotificationToken], _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.ingredientProvider.delete(ingredient, ingredients: ingredients, notificationTokens: notificationTokens) {success in
            handler(ProviderResult(status: success ? .success : .databaseUnknown))
        }
    }
    
    
    /// Helper to add/retrieve/update quantifiable product to be used for add/update ingredient
    /// NOTE: notificationToken not used here - should it? TODO!!!!!!!!!!!!!!!!!!!
    fileprivate func addOrUpdateItem(input: IngredientInput, notificationTokens: [NotificationToken], doTransaction: Bool, _ handler: @escaping (ProviderResult<(Item, Bool)>) -> Void) {
        
        let itemInput = ItemInput(name: input.name, categoryName: input.category, categoryColor: input.categoryColor, edible: true)
        
        // TODO!!!!!!!!!!!!!!!! review updateCategory parameter (updates color) here and for product - for product it's false, why?
        switch DBProv.itemProvider.mergeOrCreateItemSync(itemInput: itemInput, updateCategory: true, doTransaction: doTransaction, notificationTokens: notificationTokens) {
        case .ok(let result): handler(ProviderResult(status: .success, sucessResult: result))
        case .err(let error):
            logger.e("Error fetching item: \(error)")
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
}

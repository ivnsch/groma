//
//  RealmIngredientProvider.swift
//  Providers
//
//  Created by Ivan Schuetz on 17/01/2017.
//
//

import UIKit
import RealmSwift
import QorumLogs

class RealmIngredientProvider: RealmProvider {
    
    func ingredients(recipe: Recipe, sortBy: InventorySortBy, _ handler: @escaping (Results<Ingredient>?) -> Void) {
        
        let nameSort = SortDescriptor(keyPath: "itemOpt.name", ascending: true)
        let quantitySort = SortDescriptor(keyPath: "quantity", ascending: true)
        let unitSort = SortDescriptor(keyPath: "productOpt.unitOpt.name", ascending: true) // TODO
        
        let rest = [unitSort]
        
        let sortDescriptors: [SortDescriptor] = {
            switch sortBy {
            case .alphabetic: return [nameSort, quantitySort] // + rest
            case .count: return [quantitySort, nameSort] // + rest
            }
        }()
        
        let result = withRealmSync {realm in
            return realm.objects(Ingredient.self).filter(Ingredient.createFilter(recipeUuid: recipe.uuid)).sorted(by: sortDescriptors)
        }
        
        handler(result)
    }
    
    func add(_ quickAddInput: QuickAddIngredientInput, recipe: Recipe, ingredients: Results<Ingredient>, notificationToken: NotificationToken, _ handler: @escaping ((ingredient: Ingredient, isNew: Bool)?) -> Void) {
        
        guard let ingredientsRealm = ingredients.realm else {QL4("Ingredients have no realm"); handler(nil); return}
        
        let existingIngredientMaybe = ingredients.filter(Ingredient.createFilter(item: quickAddInput.item, recipe: recipe)).first
        
        if let existingIngredient = existingIngredientMaybe {
            update(existingIngredient, input: quickAddInput, ingredients: ingredients, notificationToken: notificationToken) {updateSuccess in
                if updateSuccess {
                    handler((ingredient: existingIngredient, isNew: false))
                } else {
                    QL4("Couldn't update existing ingredient")
                    handler(nil)
                }
            }
        } else {
            create(quickAddInput, recipe: recipe, ingredients: ingredients, notificationToken: notificationToken) {addedIngredient in
                handler(addedIngredient.map{(ingredient: $0, isNew: true)})
            }
        }
    }
    
    func increment(_ ingredient: Ingredient, quantity: Float, notificationToken: NotificationToken, realm: Realm, _ handler: @escaping (Float?) -> Void) {
        let quantityMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: realm) {realm -> Float in
            ingredient.incrementQuantity(quantity)
            return ingredient.quantity
        }
        handler(quantityMaybe)
    }

    public func update(_ ingredient: Ingredient, input: IngredientInput, ingredients: Results<Ingredient>, notificationToken: NotificationToken, _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: ingredients.realm) {realm -> Bool in
            ingredient.quantity = input.quantity
            // TODO!!!!!!!!!!!!!!!!!!!!!
            return true
        }
        handler(successMaybe ?? false)
    }
    
    
    /// When ingredients added via quick add already exist in recipe - since we don't increment ingredients, we just replace, which in this case means updating the existing item with the properties that can be entered using the quick add form.
    public func update(_ ingredient: Ingredient, input: QuickAddIngredientInput, ingredients: Results<Ingredient>, notificationToken: NotificationToken, _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: ingredients.realm) {realm -> Bool in
            ingredient.quantity = input.quantity
            ingredient.fraction = input.fraction
            ingredient.unit = input.unit
            return true
        }
        handler(successMaybe ?? false)
    }
    
    public func delete(_ ingredient: Ingredient, ingredients: Results<Ingredient>, notificationToken: NotificationToken, _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: ingredients.realm) {realm -> Bool in
            ingredients.realm?.delete(ingredients.filter(Ingredient.createFilter(uuid: ingredient.uuid)))
            return true
        }
        handler(successMaybe ?? false)
    }
    
//    // TODO remove
//    // Handler returns true if it deleted something, false if there was nothing to delete or an error ocurred.
//    func deletePossibleIngredient(quantifiableProductUnique: QuantifiableProductUnique, recipe: Recipe, notUuid: String, handler: @escaping (Bool) -> Void) {
//        removeReturnCount(Ingredient.createFilter(recipeUuid: recipe.uuid, quantifiableProductUnique: quantifiableProductUnique, notUuid: notUuid), handler: {removedCountMaybe in
//            if let removedCount = removedCountMaybe {
//                if removedCount > 0 {
//                    QL2("Found ingredient with same unique in list, deleted it. Unique: \(quantifiableProductUnique), recipe: {\(recipe.uuid), \(recipe.name)}")
//                }
//            } else {
//                QL4("Remove didn't succeed: Unique: \(quantifiableProductUnique), recipe: {\(recipe.uuid), \(recipe.name)}")
//            }
//            handler(removedCountMaybe.map{$0 > 0} ?? false)
//        }, objType: Ingredient.self)
//    }
    
    // Handler returns true if it deleted something, false if there was nothing to delete or an error ocurred.
    // Note: itemName is the ingredient's unique! Unit isn't included. Listing the same ingredient(name) in a recipe multiple times with different units doesn't seem to make sense. Also haven't seen recipes with this so far.
    func deletePossibleIngredient(itemName: String, recipe: Recipe, notUuid: String, handler: @escaping (Bool) -> Void) {
        removeReturnCount(Ingredient.createFilter(recipeUuid: recipe.uuid, name: itemName, notUuid: notUuid), handler: {removedCountMaybe in
            if let removedCount = removedCountMaybe {
                if removedCount > 0 {
                    QL2("Found ingredient with same unique in list, deleted it. Name: \(itemName), recipe: {\(recipe.uuid), \(recipe.name)}")
                }
            } else {
                QL4("Remove didn't succeed: Name: \(itemName), recipe: {\(recipe.uuid), \(recipe.name)}")
            }
            handler(removedCountMaybe.map{$0 > 0} ?? false)
        }, objType: Ingredient.self)
    }
    
    // MARK: - private
    
    fileprivate func create(_ quickAddInput: QuickAddIngredientInput, recipe: Recipe, ingredients: Results<Ingredient>, notificationToken: NotificationToken, _ handler: @escaping (Ingredient?) -> Void) {
        let ingredient = Ingredient(uuid: UUID().uuidString, quantity: quickAddInput.quantity, fraction: quickAddInput.fraction, unit: quickAddInput.unit, item: quickAddInput.item, recipe: recipe)
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: ingredients.realm) {realm -> Bool in
            realm.add(ingredient, update: true) // update: true "just in case", not really necessary
            return true
        }
        handler((successMaybe ?? false) ? ingredient : nil)
    }
}

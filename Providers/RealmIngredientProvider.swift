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
        let unitSort = SortDescriptor(keyPath: "productOpt.unitVal", ascending: true) // TODO
        
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
//
//    // TODO remove
//    func add(_ quantifiableProduct: QuantifiableProduct, quantity: Int, recipe: Recipe, ingredients: Results<Ingredient>, notificationToken: NotificationToken, _ handler: @escaping ((ingredient: Ingredient, isNew: Bool)?) -> Void) {
//        
//        guard let ingredientsRealm = ingredients.realm else {QL4("Ingredients have no realm"); handler(nil); return}
//        
//        let existingIngredientMaybe = ingredients.filter(Ingredient.createFilter(product: quantifiableProduct, recipe: recipe)).first
//        
//        if let existingIngredient = existingIngredientMaybe {
//            increment(existingIngredient, quantity: quantity, notificationToken: notificationToken, realm: ingredientsRealm) {quantityMaybe in
//                if quantityMaybe != nil {
//                    handler((ingredient: existingIngredient, isNew: false))
//                } else {
//                    QL4("Couldn't increment existing ingredient")
//                    handler(nil)
//                }
//            }
//        } else {
//            create(quantifiableProduct, quantity: quantity, recipe: recipe, ingredients: ingredients, notificationToken: notificationToken) {addedIngredient in
//                handler(addedIngredient.map{(ingredient: $0, isNew: true)})
//            }
//        }
//    }
    
    
    func add(_ quickAddInput: QuickAddIngredientInput, recipe: Recipe, ingredients: Results<Ingredient>, notificationToken: NotificationToken, _ handler: @escaping ((ingredient: Ingredient, isNew: Bool)?) -> Void) {
        
        guard let ingredientsRealm = ingredients.realm else {QL4("Ingredients have no realm"); handler(nil); return}
        
        let existingIngredientMaybe = ingredients.filter(Ingredient.createFilter(item: quickAddInput.item, recipe: recipe)).first
        
        if let existingIngredient = existingIngredientMaybe {
            increment(existingIngredient, quantity: quickAddInput.quantity, notificationToken: notificationToken, realm: ingredientsRealm) {quantityMaybe in
                if quantityMaybe != nil {
                    handler((ingredient: existingIngredient, isNew: false))
                } else {
                    QL4("Couldn't increment existing ingredient")
                    handler(nil)
                }
            }
        } else {
            create(quickAddInput.item, quantity: quickAddInput.quantity, recipe: recipe, ingredients: ingredients, notificationToken: notificationToken) {addedIngredient in
                handler(addedIngredient.map{(ingredient: $0, isNew: true)})
            }
        }
    }
    
    func increment(_ ingredient: Ingredient, quantity: Int, notificationToken: NotificationToken, realm: Realm, _ handler: @escaping (Int?) -> Void) {
        let quantityMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: realm) {realm -> Int in
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
    
    fileprivate func create(_ item: Item, quantity: Int, recipe: Recipe, ingredients: Results<Ingredient>, notificationToken: NotificationToken, _ handler: @escaping (Ingredient?) -> Void) {
        let ingredient = Ingredient(uuid: UUID().uuidString, quantity: quantity, item: item, recipe: recipe)
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: ingredients.realm) {realm -> Bool in
            realm.add(ingredient, update: true) // update: true "just in case", not really necessary
            return true
        }
        handler((successMaybe ?? false) ? ingredient : nil)
    }
}

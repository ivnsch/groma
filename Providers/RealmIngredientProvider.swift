//
//  RealmIngredientProvider.swift
//  Providers
//
//  Created by Ivan Schuetz on 17/01/2017.
//
//

import UIKit
import RealmSwift



public struct AddRecipeIngredientModel {
    public var productPrototype: ProductPrototype
    public var quantity: Float
    public let ingredient: Ingredient // The unmodified ingredient (to pass around)
    
    public init(productPrototype: ProductPrototype, quantity: Float, ingredient: Ingredient) {
        self.productPrototype = productPrototype
        self.quantity = quantity
        self.ingredient = ingredient
    }
}


class RealmIngredientProvider: RealmProvider {
    
    func ingredients(recipe: Recipe, sortBy: InventorySortBy, _ handler: @escaping (Results<Ingredient>?) -> Void) {
        
        let nameSort = SortDescriptor(keyPath: "itemOpt.name", ascending: true)
        let quantitySort = SortDescriptor(keyPath: "quantity", ascending: true)
//        let unitSort = SortDescriptor(keyPath: "productOpt.unitOpt.name", ascending: true) // TODO
        
//        let rest = [unitSort]
        
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
    
    func add(_ quickAddInput: QuickAddIngredientInput, recipe: Recipe, ingredients: Results<Ingredient>, notificationTokens: [NotificationToken], _ handler: @escaping ((ingredient: Ingredient, isNew: Bool)?) -> Void) {
        
        // We don't wait until execution finishes or handle error if it fails, since this is not critical
        func incrementFav() {
            DBProv.itemProvider.incrementFav(itemUuid: quickAddInput.item.uuid, transactionRealm: nil, {saved in
                if !saved {
                    logger.e("Couldn't increment item fav")
                }
            })
        }
        
        guard ingredients.realm != nil else {logger.e("Ingredients have no realm"); handler(nil); return}
        
        let existingIngredientMaybe = ingredients.filter(Ingredient.createFilter(item: quickAddInput.item, recipe: recipe)).first
        
        if let existingIngredient = existingIngredientMaybe {
            update(existingIngredient, input: quickAddInput, ingredients: ingredients, notificationTokens: notificationTokens) {updateSuccess in
                if updateSuccess {
                    incrementFav()
                    handler((ingredient: existingIngredient, isNew: false))
                } else {
                    logger.e("Couldn't update existing ingredient")
                    handler(nil)
                }
            }
        } else {
            create(quickAddInput, recipe: recipe, ingredients: ingredients, notificationTokens: notificationTokens) {addedIngredient in
                incrementFav()
                handler(addedIngredient.map{(ingredient: $0, isNew: true)})
            }
        }
    }
    
    func add(ingredients: [Ingredient]) -> Bool {
        return saveObjsSync(ingredients)
    }
    
    func increment(_ ingredient: Ingredient, quantity: Float, notificationTokens: [NotificationToken], realm: Realm, _ handler: @escaping (Float?) -> Void) {
        let quantityMaybe = doInWriteTransactionSync(withoutNotifying: notificationTokens, realm: realm) {realm -> Float in
            ingredient.incrementQuantity(quantity)
            return ingredient.quantity
        }
        handler(quantityMaybe)
    }

    public func update(_ ingredient: Ingredient, input: IngredientInput, item: Item?, ingredients: Results<Ingredient>, notificationTokens: [NotificationToken], _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: notificationTokens, realm: ingredients.realm) {realm -> Bool in
            ingredient.quantity = input.quantity
            ingredient.unit = input.unit
            if let fraction = input.fraction {
                ingredient.fraction = fraction
            }
            if let item = item {
                ingredient.item = item
            }
            return true
        }
        handler(successMaybe ?? false)
    }
    
    
    /// When ingredients added via quick add already exist in recipe - since we don't increment ingredients, we just replace, which in this case means updating the existing item with the properties that can be entered using the quick add form.
    public func update(_ ingredient: Ingredient, input: QuickAddIngredientInput, ingredients: Results<Ingredient>, notificationTokens: [NotificationToken], _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: notificationTokens, realm: ingredients.realm) {realm -> Bool in
            ingredient.quantity = input.quantity
            ingredient.fraction = input.fraction
            ingredient.unit = input.unit
            return true
        }
        handler(successMaybe ?? false)
    }
    
    func updateLastProductInputs(ingredientModels: [AddRecipeIngredientModel], _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [], realm: nil) {realm -> Bool in
            for model in ingredientModels {
                model.ingredient.updateLastProductInputs(prototype: model.productPrototype, quantity: model.quantity)
            }
            return true
        }
        handler(successMaybe ?? false)
    }
    
    public func delete(_ ingredient: Ingredient, ingredients: Results<Ingredient>, notificationTokens: [NotificationToken], _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: notificationTokens, realm: ingredients.realm) {realm -> Bool in
            let toDelete = ingredients.filter(Ingredient.createFilter(uuid: ingredient.uuid))
            ingredients.realm?.delete(toDelete)
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
//                    logger.d("Found ingredient with same unique in list, deleted it. Unique: \(quantifiableProductUnique), recipe: {\(recipe.uuid), \(recipe.name)}")
//                }
//            } else {
//                logger.e("Remove didn't succeed: Unique: \(quantifiableProductUnique), recipe: {\(recipe.uuid), \(recipe.name)}")
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
                    logger.d("Found ingredient with same unique in list, deleted it. Name: \(itemName), recipe: {\(recipe.uuid), \(recipe.name)}")
                }
            } else {
                logger.e("Remove didn't succeed: Name: \(itemName), recipe: {\(recipe.uuid), \(recipe.name)}")
            }
            handler(removedCountMaybe.map{$0 > 0} ?? false)
        }, objType: Ingredient.self)
    }
    
    // MARK: - private
    
    fileprivate func create(_ quickAddInput: QuickAddIngredientInput, recipe: Recipe, ingredients: Results<Ingredient>, notificationTokens: [NotificationToken], _ handler: @escaping (Ingredient?) -> Void) {
        let ingredient = Ingredient(uuid: UUID().uuidString, quantity: quickAddInput.quantity, fraction: quickAddInput.fraction, unit: quickAddInput.unit, item: quickAddInput.item, recipe: recipe)
        let successMaybe = doInWriteTransactionSync(withoutNotifying: notificationTokens, realm: ingredients.realm) {realm -> Bool in
            realm.add(ingredient, update: true) // update: true "just in case", not really necessary
            return true
        }
        handler((successMaybe ?? false) ? ingredient : nil)
    }
    
    // MARK: - Sync
    
    // Note: This is expected to be called from inside a transaction and in a background operation
    func deleteIngredientsAndDependenciesSync(realm: Realm, itemUuid: String) -> Bool {
        let ingredients = realm.objects(Ingredient.self).filter(Ingredient.createFilter(itemUuid: itemUuid))
        for ingredient in ingredients {
            realm.delete(ingredient)
        }
        return true
    }
}

//
//  RealmRecipeProvider.swift
//  Providers
//
//  Created by Ivan Schuetz on 17/01/2017.
//
//

import UIKit
import RealmSwift
import QorumLogs

class RealmRecipeProvider: RealmProvider {
    
    public func recipes(sortBy: RecipeSortBy, _ handler: @escaping (RealmSwift.List<Recipe>?) -> Void) {
        guard let recipesContainer: RecipesContainer = loadSync(predicate: nil)?.first else {
            handler(nil)
            QL4("Invalid state: no container")
            return
        }
        handler(recipesContainer.recipes)
    }
    
    public func add(_ recipe: Recipe, recipes: RealmSwift.List<Recipe>, notificationToken: NotificationToken, _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: recipes.realm) {realm -> Bool in
            recipes.append(recipe)
            return true
        }
        handler(successMaybe ?? false)
    }
    
    public func update(_ recipe: Recipe, input: RecipeInput, recipes: RealmSwift.List<Recipe>, notificationToken: NotificationToken, _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: recipes.realm) {realm -> Bool in
            recipe.name = input.name
            recipe.color = input.color
            return true
        }
        handler(successMaybe ?? false)
    }
    
    public func move(from: Int, to: Int, recipes: RealmSwift.List<Recipe>, notificationToken: NotificationToken, _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: recipes.realm) {realm -> Bool in
            recipes.move(from: from, to: to)
            return true
        }
        handler(successMaybe ?? false)
    }
    
    public func delete(index: Int, recipes: RealmSwift.List<Recipe>, notificationToken: NotificationToken, _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: recipes.realm) {realm -> Bool in
            recipes.remove(objectAtIndex: index)
            return true
        }
        handler(successMaybe ?? false)
    }
}

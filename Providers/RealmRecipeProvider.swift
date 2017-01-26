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

    func recipes(substring: String, range: NSRange? = nil, sortBy: RecipeSortBy, handler: @escaping ((substring: String?, recipes: [Recipe])) -> Void) {
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .alphabetic: return ("name", true)
            case .fav: return ("fav", false)
            case .order: return ("order", true)
            }
        }()
        
        
        withRealm({realm -> [String]? in
            let recipes: Results<Recipe> = self.loadSync(realm, filter: Recipe.createFilterNameContains(substring), sortDescriptor: SortDescriptor(keyPath: sortData.key, ascending: sortData.ascending))
            return recipes.toArray(range).map{$0.uuid}
            
        }) {uuidsMaybe in
            do {
                if let uuids = uuidsMaybe {
                    let realm = try Realm()
                    // TODO review if it's necessary to pass the sort descriptor here again
                    let recipes: Results<Recipe> = self.loadSync(realm, filter: Recipe.createFilterUuids(uuids), sortDescriptor: SortDescriptor(keyPath: sortData.key, ascending: sortData.ascending))
                    handler((substring, recipes.toArray()))
                    
                } else {
                    QL4("No product uuids")
                    handler((substring, []))
                }
                
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                handler((substring, []))
            }
        }
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
    
    func incrementFav(_ recipeUuid: String, _ handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            if let recipe = realm.objects(Recipe.self).filter(Recipe.createFilter(recipeUuid)).first {
                recipe.fav += 1
//                realm.add(recipe, update: true) // TODO!!!!!!!!!!!!!!!! confirm if this is not necessary and remove
                return true
            } else { // group not found
                QL4("Didn't find group to increment fav")
                return true // we return success anyway because this is not critical, no reason to show a popup to the user
            }
        }, finishHandler: {savedMaybe in
            handler(savedMaybe ?? false)
        })
    }
}

//
//  RecipeProviderImpl.swift
//  Providers
//
//  Created by Ivan Schuetz on 17/01/2017.
//
//

import UIKit
import RealmSwift

public class RecipeProviderImpl: RecipeProvider {
    
    public func recipes(sortBy: RecipeSortBy, _ handler: @escaping (ProviderResult<RealmSwift.List<Recipe>>) -> Void) {
        DBProv.recipeProvider.recipes(sortBy: sortBy) {recipesMaybe in
            if let recipes = recipesMaybe {
                handler(ProviderResult(status: .success, sucessResult: recipes))
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    public func recipes(substring: String, range: NSRange, sortBy: RecipeSortBy, _ handler: @escaping (ProviderResult<(substring: String?, recipes: [Recipe])>) -> Void) {
        DBProv.recipeProvider.recipes(substring: substring, range: range, sortBy: sortBy) {recipes in
            handler(ProviderResult(status: .success, sucessResult: recipes))
        }
    }
    
    public func add(_ recipe: Recipe, recipes: RealmSwift.List<Recipe>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.recipeProvider.add(recipe, recipes: recipes, notificationToken: notificationToken) {success in
            handler(ProviderResult(status: success ? .success : .databaseUnknown))
        }
    }
    
    public func update(_ recipe: Recipe, input: RecipeInput, recipes: RealmSwift.List<Recipe>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.recipeProvider.update(recipe, input: input, recipes: recipes, notificationToken: notificationToken) {success in
            handler(ProviderResult(status: success ? .success : .databaseUnknown))
        }
    }
    
    public func move(from: Int, to: Int, recipes: RealmSwift.List<Recipe>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.recipeProvider.move(from: from, to: to, recipes: recipes, notificationToken: notificationToken) {success in
            handler(ProviderResult(status: success ? .success : .databaseUnknown))
        }
    }
    
    public func delete(index: Int, recipes: RealmSwift.List<Recipe>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.recipeProvider.delete(index: index, recipes: recipes, notificationToken: notificationToken) {success in
            handler(ProviderResult(status: success ? .success : .databaseUnknown))
        }
    }
    
    public func incrementFav(_ recipeUuid: String, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        DBProv.recipeProvider.incrementFav(recipeUuid, {saved in
            handler(ProviderResult(status: saved ? .success : .databaseUnknown))
        })
    }
}

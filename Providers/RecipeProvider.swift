//
//  RecipeProvider.swift
//  Providers
//
//  Created by Ivan Schuetz on 17/01/2017.
//
//

import UIKit
import RealmSwift

public enum RecipeSortBy {
    case alphabetic, fav, order
}

public protocol RecipeProvider {

    // TODO!!!!!!!!!!!! is sortby being used?
    func recipes(sortBy: RecipeSortBy, _ handler: @escaping (ProviderResult<RealmSwift.List<Recipe>>) -> Void)

    func recipes(substring: String, range: NSRange, sortBy: RecipeSortBy, _ handler: @escaping (ProviderResult<(substring: String?, recipes: [Recipe])>) -> Void)

    func add(_ recipe: Recipe, notificationToken: NotificationToken?, _ handler: @escaping (ProviderResult<Any>) -> Void)

    func add(_ recipe: Recipe, recipes: RealmSwift.List<Recipe>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func update(_ recipe: Recipe, input: RecipeInput, recipes: RealmSwift.List<Recipe>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void)

    func update(_ recipe: Recipe, recipeText: String, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void)

    func move(from: Int, to: Int, recipes: RealmSwift.List<Recipe>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func delete(index: Int, recipes: RealmSwift.List<Recipe>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func incrementFav(_ recipeUuid: String, _ handler: @escaping (ProviderResult<Any>) -> Void)
}

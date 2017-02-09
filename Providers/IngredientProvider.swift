//
//  IngredientProvider.swift
//  Providers
//
//  Created by Ivan Schuetz on 17/01/2017.
//
//

import Foundation
import RealmSwift

public protocol IngredientProvider {
    
    func ingredients(recipe: Recipe, sortBy: InventorySortBy, _ handler: @escaping (ProviderResult<Results<Ingredient>>) -> Void)

    // NOTE: we pass recipe despite there's a reference to recipe in ingredient. That this is the case, and that the recipe in ingredient is also set correctly can be seen as an assumption. In fact, we don't really need the recipe reference in ingredient as now we model more in accordance to Realm's design, where the parent has the references to the children. Letting it there just in case. Maybe it should be removed.
    func add(_ quickAddInput: QuickAddIngredientInput, recipe: Recipe, ingredients: Results<Ingredient>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<(ingredient: Ingredient, isNew: Bool)>) -> Void)

    
    // Input form (create)
    func add(_ input: IngredientInput, recipe: Recipe, ingredients: Results<Ingredient>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    // NOTE: the realm has to be from Results where notificationToken comes from, otherwise sup pressing of notifications doesn't work.
    func increment(_ ingredient: Ingredient, quantity: Float, notificationToken: NotificationToken, realm: Realm, _ handler: @escaping (ProviderResult<Float>) -> Void)
    
    // Input form (update)
    func update(_ ingredient: Ingredient, input: IngredientInput, ingredients: Results<Ingredient>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<(ingredient: Ingredient, replaced: Bool)>) -> Void)
    
    func delete(_ ingredient: Ingredient, ingredients: Results<Ingredient>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void)
}

//
//  Ingredient.swift
//  Providers
//
//  Created by Ivan Schuetz on 17/01/2017.
//
//

import Foundation
import RealmSwift
import QorumLogs

public final class Ingredient: Object {
    public dynamic var uuid: String = ""
    public dynamic var quantity: Int = 0
    dynamic var itemOpt: Item? = Item()
    dynamic var recipeOpt: Recipe? = Recipe()
    
    public static var quantityFieldName: String {
        return "quantity"
    }
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }

    public var item: Item {
        get {
            return itemOpt ?? Item()
        }
        set(newItem) {
            itemOpt = newItem
        }
    }
    

    
    public var recipe: Recipe {
        get {
            return recipeOpt ?? Recipe()
        }
        set(newRecipe) {
            recipeOpt = newRecipe
        }
    }

    public convenience init(uuid: String, quantity: Int, item: Item, recipe: Recipe) {
        self.init()
        
        self.uuid = uuid
        self.quantity = quantity
        self.item = item
        self.recipe = recipe
    }
    
    // MARK: - Filters
    
    static func createFilter(uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }

    static func createFilter(name: String, recipeUuid: String) -> String {
        return "item.name == '\(name)' AND recipe.uuid == '\(recipeUuid)'"
    }
    
    static func createFilter(recipeUuid: String) -> String {
        return "recipeOpt.uuid = '\(recipeUuid)'"
    }
    
    static func createFilter(item: Item, recipe: Recipe) -> String {
        return "\(createFilter(recipeUuid: recipe.uuid)) AND itemOpt.uuid == '\(item.uuid)'"
    }
    
//    static func createFilter(recipeUuid: String, quantifiableProductUnique unique: QuantifiableProductUnique) -> String {
//        return "\(createFilter(recipeUuid: recipeUuid)) AND itemOpt.name = '\(unique.name)' AND productOpt.productOpt.brand = '\(unique.brand)' AND productOpt.unitVal = \(unique.unit.rawValue) AND productOpt.baseQuantity = '\(unique.baseQuantity)'"
//    }
    
    static func createFilter(recipeUuid: String, name: String, notUuid: String) -> String {
        return "\(createFilter(name: name, recipeUuid: recipeUuid)) AND uuid != '\(notUuid)'"
    }
    
    static func createFilterGroupItemsUuids(ingredients: [Ingredient]) -> String {
        let ingredientsUuidsStr = ingredients.map{"'\($0.uuid)'"}.joined(separator: ",")
        return "uuid IN {\(ingredientsUuidsStr)}"
    }
    
    public override static func ignoredProperties() -> [String] {
        return ["recipe", "item"]
    }
    
    // MARK: - ProductWithQuantity2 (REMOVED) TODO clean up
    
    
    public func copy(uuid: String? = nil, quantity: Int? = nil, item: Item? = nil, recipe: Recipe? = nil) -> Ingredient {
        return Ingredient(
            uuid: uuid ?? self.uuid,
            quantity: quantity ?? self.quantity,
            item: item ?? self.item,
            recipe: recipe ?? self.recipe.copy()
        )
    }
    
    public func incrementQuantity(_ delta: Int) {
        let updatedQuantity = quantity + delta
        if updatedQuantity >= 0 {
            quantity = quantity + delta
        } else {
            QL1("Trying to decrement quantity to less than zero. Current quantity: \(quantity), delta: \(delta). Setting it to 0.")
            quantity = 0
        }
    }
    
    public func incrementQuantityCopy(_ delta: Int) -> Ingredient {
        return copy(quantity: quantity + delta)
    }
    
    public func updateQuantityCopy(_ quantity: Int) -> Ingredient {
        return copy(quantity: quantity)
    }
    
    public override var description: String {
        return "{\(type(of: self)) uuid: \(uuid), name: \(item.name), quantity: \(quantity)}"
    }
    
    // MARK: - Identifiable
    
    /**
     If objects have the same semantic identity. Identity is equivalent to a primary key in a database.
     */
    public func same(_ rhs: Ingredient) -> Bool {
        return uuid == rhs.uuid
    }
    
    public static func unitText(quantity: Int, baseQuantity: Float, unit: ProductUnit, showNoneText: Bool = false) -> String {
        let quantifiableProductUnitText = QuantifiableProduct.unitText(baseQuantity: baseQuantity, unit: unit, showNoneText: showNoneText, pluralUnit: quantity > 1)
        return "\(quantity)\(quantifiableProductUnitText)"
    }
}

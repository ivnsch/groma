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

public final class Ingredient: Object, ProductWithQuantity2 {
    public dynamic var uuid: String = ""
    public dynamic var quantity: Int = 0
    dynamic var productOpt: QuantifiableProduct? = QuantifiableProduct()
    dynamic var recipeOpt: Recipe? = Recipe()
    
    public static var quantityFieldName: String {
        return "quantity"
    }
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public var product: QuantifiableProduct {
        get {
            return productOpt ?? QuantifiableProduct()
        }
        set(newProduct) {
            productOpt = newProduct
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
    
    public convenience init(uuid: String, quantity: Int, product: QuantifiableProduct, recipe: Recipe) {
        self.init()
        
        self.uuid = uuid
        self.quantity = quantity
        self.product = product
        self.recipe = recipe
    }
    
    // MARK: - Filters
    
    static func createFilter(uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilter(recipeUuid: String) -> String {
        return "recipeOpt.uuid = '\(recipeUuid)'"
    }
    
    static func createFilterProduct(_ productUuid: String) -> String {
        return "productOpt.uuid = '\(productUuid)'"
    }
    
    static func createFilter(product: QuantifiableProduct, recipe: Recipe) -> String {
        return createFilter(recipeUuid: recipe.uuid, quantifiableProductUnique: product.unique)
    }
    
    static func createFilter(recipeUuid: String, quantifiableProductUnique unique: QuantifiableProductUnique) -> String {
        return "\(createFilter(recipeUuid: recipeUuid)) AND productOpt.productOpt.name = '\(unique.name)' AND productOpt.productOpt.brand = '\(unique.brand)' AND productOpt.unitVal = \(unique.unit.rawValue) AND productOpt.baseQuantity = \(unique.baseQuantity)"
    }
    
    static func createFilter(recipeUuid: String, quantifiableProductUnique unique: QuantifiableProductUnique, notUuid: String) -> String {
        return "\(createFilter(recipeUuid: recipeUuid, quantifiableProductUnique: unique)) AND uuid != '\(notUuid)'"
    }
    
    static func createFilterGroupItemsUuids(ingredients: [Ingredient]) -> String {
        let ingredientsUuidsStr = ingredients.map{"'\($0.uuid)'"}.joined(separator: ",")
        return "uuid IN {\(ingredientsUuidsStr)}"
    }
    
    public override static func ignoredProperties() -> [String] {
        return ["product", "recipe"]
    }
    
    // MARK: - ProductWithQuantity2
    
    public func copy(uuid: String? = nil, quantity: Int? = nil, product: QuantifiableProduct? = nil, recipe: Recipe? = nil) -> Ingredient {
        return Ingredient(
            uuid: uuid ?? self.uuid,
            quantity: quantity ?? self.quantity,
            product: product ?? self.product.copy(),
            recipe: recipe ?? self.recipe.copy()
        )
    }
    
    public func incrementQuantity(_ delta: Int) {
        let updatedQuantity = quantity + delta
        if updatedQuantity >= 0 {
            quantity = quantity + delta
        } else {
            QL3("Trying to decrement quantity to less than zero. Current quantity: \(quantity), delta: \(delta). Setting it to 0.")
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
        return "{\(type(of: self)) uuid: \(uuid), name: \(product.product.name), quantity: \(quantity), unit: \(product.unit)}"
    }
    
    // MARK: - Identifiable
    
    /**
     If objects have the same semantic identity. Identity is equivalent to a primary key in a database.
     */
    public func same(_ rhs: Ingredient) -> Bool {
        return uuid == rhs.uuid
    }
}

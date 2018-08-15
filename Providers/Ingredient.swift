//
//  Ingredient.swift
//  Providers
//
//  Created by Ivan Schuetz on 17/01/2017.
//
//

import Foundation
import RealmSwift


public final class Ingredient: Object, WithUuid {
    @objc public dynamic var uuid: String = ""
    @objc public dynamic var quantity: Float = 0
    @objc public dynamic var fractionNumerator: Int = 0
    @objc public dynamic var fractionDenominator: Int = 1 // To avoid potential division by 0 - as long as numerator is 0 fraction is non-op
    
    @objc dynamic var unitOpt: Unit? = Unit()
    @objc dynamic var itemOpt: Item? = Item()
    @objc dynamic var recipeOpt: Recipe? = Recipe()
    
    /// Remember the last inputs entered by user when adding this ingredient to a shopping list (p stands for "product")
    /// We use this to prefill the next time user adds this ingredient to a list
    @objc public dynamic var pName: String = ""
    @objc public dynamic var pBrand: String = ""
    @objc public dynamic var pBase: Float = 1
    @objc public dynamic var pSecondBase: Float = 1
    @objc public dynamic var pQuantity: Float = 0
    @objc public dynamic var pUnit: String = ""

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
    
    public var unit: Unit {
        get {
            return unitOpt ?? Unit()
        }
        set {
            unitOpt = newValue
        }
    }

    public var fraction: Fraction {
        get {
            return Fraction(wholeNumber: 0, numerator: fractionNumerator, denominator: fractionDenominator)
        }
        set {
            fractionNumerator = newValue.numerator
            fractionDenominator = newValue.denominator
        }
    }

    public convenience init(uuid: String, quantity: Float, fraction: Fraction, unit: Unit, item: Item, recipe: Recipe) {
        self.init(uuid: uuid, quantity: quantity, item: item, recipe: recipe)
        self.fraction = fraction
        self.unit = unit
    }
    
    // TODO deprecated remove
    public convenience init(uuid: String, quantity: Float, item: Item, recipe: Recipe) {
        self.init()
        
        self.uuid = uuid
        self.quantity = quantity
        self.item = item
        self.recipe = recipe
    }
    
    // MARK: - Filters

    static func createFilter(uuid: String) -> NSPredicate {
        return NSPredicate(format: "uuid = %@", uuid)
    }

    static func createFilter(itemUuid: String) -> NSPredicate {
        return NSPredicate(format: "itemOpt.uuid = %@", itemUuid)
    }

    static func createFilter(recipeUuid: String) -> NSPredicate {
        return NSPredicate(format: "recipeOpt.uuid = %@", recipeUuid)
    }

    static func createFilter(unitName: String) -> NSPredicate {
        return NSPredicate(format: "unitOpt.name = %@", unitName)
    }

    static func createFilterGroupItemsUuids(ingredients: [Ingredient]) -> NSPredicate {
        let ingredientsUuids = ingredients.map{$0.uuid}
        return NSPredicate(format: "uuid IN %@", ingredientsUuids)
    }

    static func createFilter(name: String, recipeUuid: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "itemOpt.name = %@", name),
            createFilter(recipeUuid: recipeUuid)
        ])
    }

    static func createFilter(item: Item, recipe: Recipe) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            createFilter(recipeUuid: recipe.uuid),
            createFilter(itemUuid: item.uuid)
        ])
    }

    static func createFilter(recipeUuid: String, name: String, notUuid: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            createFilter(name: name, recipeUuid: recipeUuid),
            NSPredicate(format: "uuid != %@", notUuid)
        ])
    }

    public override static func ignoredProperties() -> [String] {
        return ["recipe", "item", "unit", "fraction"]
    }
    
    // MARK: - ProductWithQuantity2 (REMOVED) TODO clean up
    
    
    public func copy(uuid: String? = nil, quantity: Float? = nil, fraction: Fraction? = nil, unit: Unit? = nil, item: Item? = nil, recipe: Recipe? = nil) -> Ingredient {
        return Ingredient(
            uuid: uuid ?? self.uuid,
            quantity: quantity ?? self.quantity,
            fraction: fraction ?? self.fraction,
            unit: unit ?? self.unit.copy(),
            item: item ?? self.item.copy(),
            recipe: recipe ?? self.recipe.copy()
        )
    }
    
    public func incrementQuantity(_ delta: Float) {
        let updatedQuantity = quantity + delta
        if updatedQuantity >= 0 {
            quantity = quantity + delta
        } else {
            logger.v("Trying to decrement quantity to less than zero. Current quantity: \(quantity), delta: \(delta). Setting it to 0.")
            quantity = 0
        }
    }
    
    public func incrementQuantityCopy(_ delta: Float) -> Ingredient {
        return copy(quantity: quantity + delta)
    }
    
    public func updateQuantityCopy(_ quantity: Float) -> Ingredient {
        return copy(quantity: quantity)
    }
    
    public override var description: String {
        return "{\(type(of: self)) uuid: \(uuid), name: \(item.name), quantity: \(quantity)}"
    }
    
    /// Updates the last product inputs with prototype and quantity. The reason we use ProductPrototype is only that it's the class we currently use in AddRecipeController to store the inputs
    public func updateLastProductInputs(prototype: ProductPrototype, quantity: Float) {
        pName = prototype.name
        pBrand = prototype.brand
        pUnit = prototype.unit
        pBase = prototype.baseQuantity
        pSecondBase = prototype.secondBaseQuantity
        pQuantity = quantity
    }
    
    // MARK: - Identifiable
    
    /**
     If objects have the same semantic identity. Identity is equivalent to a primary key in a database.
     */
    public func same(_ rhs: Ingredient) -> Bool {
        return uuid == rhs.uuid
    }
    
    public static func quantityFullText(quantity: Float, baseQuantity: Float, secondBaseQuantity: Float, unit: Providers.Unit?) -> String {
        return quantityFullText(quantity: quantity, baseQuantity: baseQuantity, secondBaseQuantity: secondBaseQuantity,  unitId: unit?.id, unitName: unit?.name ?? "")
    }

    public static func quantityFullText(quantity: Float, baseQuantity: Float, secondBaseQuantity: Float, unitId: UnitId?, unitName: String, showNoneUnitName: Bool = false) -> String {

        let noneUnitName = quantity > 1 ? trans("recipe_unit_plural") : trans("recipe_unit_singular")

        let showBaseQuantity = unitId.map { _ in
//            Providers.Unit.unitsWithBase.contains($0)
            true
        } ?? false /* false: if there's no unit, unit is none -> none has no base */ && baseQuantity > 1

        let secondBaseText = showBaseQuantity && secondBaseQuantity > 1 ? secondBaseQuantity.quantityString : ""
        let secondBaseSuffix = secondBaseText.isEmpty ? "" : " x "
        let baseText = showBaseQuantity ? " x \(secondBaseText)\(secondBaseSuffix)\(baseQuantity.quantityString)" : ""
        var unitText = unitId.map{$0 == .none ? noneUnitName : unitName} ?? noneUnitName
        if !showNoneUnitName && unitText == noneUnitName {
            unitText = ""
        }
        let baseAndUnitTextSeparator = baseText.isEmpty && unitText.isEmpty ? "" : " "
        let baseAndUnitText = "\(baseText)\(baseAndUnitTextSeparator)\(unitText)"
        let afterQuantity = baseAndUnitText.isEmpty ? "" : "\(baseAndUnitText)"

        return "\(quantity.quantityString)\(afterQuantity)"
    }

    func toRealmMigrationDict(recipe: Recipe, unit: Unit, item: Item) -> [String: Any] {
        var dict = [String: Any]()
        dict["uuid"] = uuid as AnyObject?
        dict["quantity"] = quantity as AnyObject?
        dict["fractionNumerator"] = fractionNumerator as AnyObject?
        dict["fractionDenominator"] = fractionDenominator as AnyObject?

        dict["unitOpt"] = unit
        dict["itemOpt"] = item
        dict["recipeOpt"] = recipe

        dict["pName"] = pName as AnyObject?
        dict["pBrand"] = pBrand as AnyObject?
        dict["pBase"] = pBase as AnyObject?
        dict["pSecondBase"] = pSecondBase as AnyObject?
        dict["pQuantity"] = pQuantity as AnyObject?
        dict["pUnit"] = pUnit as AnyObject?

        return dict
    }

}

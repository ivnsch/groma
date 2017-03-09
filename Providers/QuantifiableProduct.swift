//
//  QuantifiableProduct.swift
//  Providers
//
//  Created by Ivan Schuetz on 11/01/2017.
//
//

import UIKit
import RealmSwift
import QorumLogs

public enum ItemUnit: Int {
    case none = 0
    case gram = 1
    case kilogram = 2
    
    public var text: String {
        switch self {
        case .none: return ""
        case .gram: return "Gram"
        case .kilogram: return "Kilogram"
        }
    }
    
    public var shortText: String {
        switch self {
        case .none: return ""
        case .gram: return "g"
        case .kilogram: return "kg"
        }
    }
}


public class QuantifiableProduct: DBSyncable, Identifiable {
    
    public dynamic var uuid: String = ""
    dynamic var productOpt: Product? = Product()
    public dynamic var baseQuantity: Float = 1
    dynamic var unitOpt: Unit? = Unit()
    public dynamic var fav: Int = 0 // not used anymore as we fav again the product, but letting it here just in case. Maybe remove.
    
    public var product: Product {
        get {
            return productOpt ?? Product()
        }
        set(newProduct) {
            productOpt = newProduct
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
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public convenience init(uuid: String, baseQuantity: Float, unit: Unit, product: Product, fav: Int = 0) {
        
        self.init()
        
        self.uuid = uuid
        self.baseQuantity = baseQuantity
        self.unit = unit
        self.product = product
        self.fav = fav
    }
    
    public func copy(uuid: String? = nil, baseQuantity: Float? = nil, unit: Unit? = nil, product: Product? = nil, fav: Int? = nil) -> QuantifiableProduct {
        return QuantifiableProduct(
            uuid: uuid ?? self.uuid,
            baseQuantity: baseQuantity ?? self.baseQuantity,
            unit: unit ?? self.unit.copy(),
            product: product ?? self.product.copy(),
            fav: fav ?? self.fav
        )
    }
    
    // MARK: - Filters
    
    static func createFilter(_ uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilter(unique: QuantifiableProductUnique) -> String {
        return "productOpt.itemOpt.name == '\(unique.name)' AND productOpt.brand == '\(unique.brand)' AND baseQuantity == \(unique.baseQuantity) AND unitOpt.name == '\(unique.unit)'"
    }
    
    static func createFilterBrand(_ brand: String) -> String {
        return "productOpt.brand == '\(brand)'"
    }
    
    static func createFilterStore(_ store: String) -> String {
        return "store == '\(store)'"
    }
    
    static func createFilterProduct(_ productUuid: String) -> String {
        return "productOpt.uuid == '\(productUuid)'"
    }

    static func createFilterNameBrand(_ name: String, brand: String, store: String) -> String {
        return "\(createFilterName(name)) AND \(createFilterBrand(brand)) AND \(createFilterStore(store))"
    }
    
    static func createFilterName(_ name: String) -> String {
        return "productOpt.itemOpt.name = '\(name)'"
    }
    
    static func createFilterNameContains(_ text: String) -> String {
        return "productOpt.itemOpt.name CONTAINS[c] '\(text)'"
    }
    
    static func createFilterBrandContains(_ text: String) -> String {
        return "productOpt.brand CONTAINS[c] '\(text)'"
    }
    
    static func createFilterStoreContains(_ text: String) -> String {
        return "store CONTAINS[c] '\(text)'"
    }
    
    static func createFilterCategory(_ categoryUuid: String) -> String {
        return "productOpt.categoryOpt.uuid = '\(categoryUuid)'"
    }
    
    static func createFilterCategoryNameContains(_ text: String) -> String {
        return "productOpt.categoryOpt.name CONTAINS[c] '\(text)'"
    }
    
    public override static func ignoredProperties() -> [String] {
        return ["product", "unit", "baseQuantityFloat"]
    }

    static func createFilterBaseQuantityContains(_ text: String) -> String {
        return "baseQuantity CONTAINS[c] '\(text)'"
    }
    
    static func createFilter(base: Float) -> String {
        return "baseQuantity = \(base)"
    }
    
    // Deletes by unit name
    static func createFilter(unit: Unit) -> String {
        return createFilter(unitName: unit.name)
    }
    
    static func createFilter(unitName: String) -> String {
        return "unitOpt.name = '\(unitName)'"
    }
    
    override func deleteWithDependenciesSync(_ realm: Realm, markForSync: Bool) {
        _ = RealmStoreProductProvider().deleteStoreProductDependenciesSync(realm, storeProductUuid: uuid, markForSync: markForSync)
        realm.delete(self)
    }
    
    // MARK: -
    
    // Overwrite all fields with fields of storeProduct, except uuid
    public func update(_ quantifiableProduct: QuantifiableProduct) -> QuantifiableProduct {
        return copy(quantifiableProduct: quantifiableProduct, product: quantifiableProduct.product)
    }
    
//    public func update(_ quantifiableProduct: QuantifiableProduct) -> QuantifiableProduct {
//        return copy(baseQuantity: quantifiableProduct.baseQuantity, unit: quantifiableProduct.unit)
//    }
    
    // Updates self and its dependencies with storeProduct, the references to the dependencies (uuid) are not changed
    public func updateWithoutChangingReferences(_ quantifiableProduct: QuantifiableProduct) -> QuantifiableProduct {
        let updatedProduct = product.updateWithoutChangingReferences(quantifiableProduct.product)
        return update(quantifiableProduct: quantifiableProduct, product: updatedProduct)
    }
    
    fileprivate func update(quantifiableProduct: QuantifiableProduct, product: Product) -> QuantifiableProduct {
        return copy(baseQuantity: quantifiableProduct.baseQuantity, unit: quantifiableProduct.unit, product: product)
    }
    
    fileprivate func copy(quantifiableProduct: QuantifiableProduct, product: Product) -> QuantifiableProduct {
        return copy(baseQuantity: quantifiableProduct.baseQuantity, unit: quantifiableProduct.unit, product: product)
    }
    
    public func same(_ rhs: QuantifiableProduct) -> Bool {
        return uuid == rhs.uuid
    }

    public var unique: QuantifiableProductUnique {
        return (name: product.item.name, brand: product.brand, unit: unit.name, baseQuantity: baseQuantity)
    }
    
    public func matches(unique: QuantifiableProductUnique) -> Bool {
        return product.item.name == unique.name && product.brand == unique.brand && baseQuantity == unique.baseQuantity && unit.name == unique.unit
    }
    
    static var baseQuantityNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    public func quantityWithMaybeUnitText(quantity: Float) -> String {
        let quantityStr = "\(quantity.quantityString)"
        // If there's no base quantity (it's 0 or 1 - normally we expect no-op base quantity to be 1 but just in case) we show the unit next to the quantity
        // The reason is that when there's a base quantity the unit belongs to the base quantity, and when there's none, it belongs to the quantity
        // E.g. 2x500g meat - the g refers to the base quantity, 2 is only units. But products that don't have a fixed base quantity (and a unit) - e.g. meat from the fridge, which can be 234.5g, has a base quantity of 1 and to not confuse the user we just don't show a base quantity at all but only the quantity with the unit next to it.
        // Clarification: Base quantity is the quantity of a product that can be bought in a store as a unit. We can buy a 500g of meat in a store (as a pack - but "pack" seems redundant information, as if we enter 500g as base quantity we know that it means 500 are sold as unit, and it's difficult to think about a product with a specified name, brand and base quantity, that will be sold in something different as "pack". Yes there could also be 500g sold as e.g. "Can" but this product will likely have a different name - canned meat or something). We also can buy 1g of meat in a store. The quantity (of list, inventory, group items) is just a multiplier of this base quantity)
        let unitStr = ((baseQuantity == 0 || baseQuantity == 1) && unit != .none) ? unit.name : ""
        return "\(quantityStr)\(unitStr)"
    }
    
    
    
    public var baseText: String {
        return QuantifiableProduct.baseText(baseQuantity: baseQuantity, unitName: unit.name)
    }
    
    public var baseAndUnitText: String {
        return QuantifiableProduct.baseAndUnitText(baseQuantity: baseQuantity, unitName: unit.name, pluralUnit: true)
    }
    
    // Shows base and unit. The content of any of these doesn't affect the other.
    public static func baseAndUnitText(baseQuantity: Float, unitName: String, showNoneText: Bool = false, pluralUnit: Bool = false) -> String {
        return baseAndUnitTextInternal(baseQuantity: baseQuantity, unitName: unitName, showNoneText: showNoneText, pluralUnit: pluralUnit)
    }
    
    // Shows base text and unit, only if base is a non no-op value. Used for labels that show specifically base - we show something if there's a base, otherwise nothing
    public static func baseText(baseQuantity: Float, unitName: String, showNoneText: Bool = false, pluralUnit: Bool = false) -> String {
        guard baseQuantity > 1 else {return ""} // for base quantity 1 or 0 there's no text
        
        return baseAndUnitTextInternal(baseQuantity: baseQuantity, unitName: unitName, showNoneText: showNoneText, pluralUnit: pluralUnit)
    }
    
    // NOTE: plural unit only affects .none / empty unit ("unit" / "units").
    fileprivate static func baseAndUnitTextInternal(baseQuantity: Float, unitName: String, showNoneText: Bool = false, pluralUnit: Bool = false) -> String {

        let baseQuantityText = baseQuantity > 1 ? QuantifiableProduct.baseQuantityNumberFormatter.string(from: NSNumber(value: baseQuantity))! : ""
        
        let unitText = QuantifiableProduct.unitText(unitName: unitName, showNoneText: showNoneText, pluralUnit: pluralUnit)
        
        let unitSeparator = unitName.isEmpty || baseQuantityText.isEmpty ? " " : ""
        return "\(baseQuantityText)\(unitSeparator)\(unitText)"
    }
    
    public static func unitText(unitName: String, showNoneText: Bool = false, pluralUnit: Bool = false) -> String {
        if showNoneText && unitName.isEmpty {
            if pluralUnit {
                return trans("recipe_unit_plural")
            } else {
                return trans("recipe_unit_singular")
            }
        } else {
            return unitName
        }
    }
}

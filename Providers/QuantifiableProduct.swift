//
//  QuantifiableProduct.swift
//  Providers
//
//  Created by Ivan Schuetz on 11/01/2017.
//
//

import UIKit
import RealmSwift

public enum ItemUnit: Int {
    case none = 0
    case gram = 1
    case kilogram = 2
    
    public var text: String {
        switch self {
        case .none: return "None"
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
    public dynamic var baseQuantity: Float = 0
    public dynamic var unitVal: Int = 0
    public dynamic var fav: Int = 0
    
    public var product: Product {
        get {
            return productOpt ?? Product()
        }
        set(newProduct) {
            productOpt = newProduct
        }
    }
    
    public var unit: ProductUnit {
        get {
            return ProductUnit(rawValue: unitVal)!
        }
        set(newUnit) {
            unitVal = newUnit.rawValue
        }
    }
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public convenience init(uuid: String, baseQuantity: Float, unit: ProductUnit, product: Product, fav: Int = 0) {
        
        self.init()
        
        self.uuid = uuid
        self.baseQuantity = baseQuantity
        self.unit = unit
        self.product = product
        self.fav = fav
    }
    
    public func copy(uuid: String? = nil, baseQuantity: Float? = nil, unit: ProductUnit? = nil, product: Product? = nil, fav: Int? = nil) -> QuantifiableProduct {
        return QuantifiableProduct(
            uuid: uuid ?? self.uuid,
            baseQuantity: baseQuantity ?? self.baseQuantity,
            unit: unit ?? self.unit,
            product: product ?? self.product.copy(),
            fav: fav ?? self.fav
        )
    }
    
    // MARK: - Filters
    
    static func createFilter(_ uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilter(unique: QuantifiableProductUnique) -> String {
        return "productOpt.name == '\(unique.name)' AND productOpt.brand == '\(unique.brand)' AND unitVal == '\(unique.unit.rawValue)'"
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
        return "productOpt.name = '\(name)'"
    }
    
    static func createFilterNameContains(_ text: String) -> String {
        return "productOpt.name CONTAINS[c] '\(text)'"
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
        return ["product", "unit"]
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
        return (name: product.name, brand: product.brand, unit: unit, baseQuantity: baseQuantity)
    }
    
    public func matches(unique: QuantifiableProductUnique) -> Bool {
        return product.name == unique.name && product.brand == unique.brand && baseQuantity == unique.baseQuantity && unit == unique.unit
    }
}

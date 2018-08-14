//
//  StoreProduct.swift
//  shoppin
//
//  Created by ischuetz on 07/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

//public enum StoreProductUnit: Int {
//    case none = 0
//    case gram = 1
//    case kilogram = 2
//
//    public var text: String {
//        switch self {
//        case .none: return "None"
//        case .gram: return "Gram"
//        case .kilogram: return "Kilogram"
//        }
//    }
//
//    public var shortText: String {
//        switch self {
//        case .none: return ""
//        case .gram: return "g"
//        case .kilogram: return "kg"
//        }
//    }
//}

public typealias StoreProductUnique = (quantifiableProductUnique: QuantifiableProductUnique, store: String)

public class StoreProduct: DBSyncable, Identifiable, WithUuid {
    
    @objc public dynamic var uuid: String = ""
    public let refPrice = RealmOptional<Float>()
    public let refQuantity = RealmOptional<Float>()

    @objc dynamic var productOpt: QuantifiableProduct? = QuantifiableProduct()

    // Multiply this with quantity = totalPrice
    public var basePrice: Float {
        let refQuantity = self.refQuantity.value ?? 0
        return StoreProduct.calculateBasePrice(refQuantity: refQuantity, refPrice: refPrice.value ?? 0, baseQuantity: product.baseQuantity, secondBaseQuantity: product.secondBaseQuantity)
    }

    public static func calculateBasePrice(refQuantity: Float, refPrice: Float, baseQuantity: Float, secondBaseQuantity: Float?) -> Float {
        let secondBaseQuantityForMaths = secondBaseQuantity ?? 1 // no second base = 1, which is identity
        return refQuantity == 0 ? 0 : (secondBaseQuantityForMaths * baseQuantity * refPrice) / refQuantity
    }


    // TODO remove
    @objc public dynamic var baseQuantity: String = ""
    
    @objc public dynamic var store: String = ""
    
    public var product: QuantifiableProduct {
        get {
            return productOpt ?? QuantifiableProduct()
        }
        set(newProduct) {
            productOpt = newProduct
        }
    }
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }

    public convenience init(uuid: String, refPrice: Float?, refQuantity: Float?, store: String = "", product: QuantifiableProduct, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
        self.init()
        
        self.uuid = uuid
        self.refPrice.value = refPrice
        self.refQuantity.value = refQuantity
        self.store = store
        self.product = product
        
        if let lastServerUpdate = lastServerUpdate {
            self.lastServerUpdate = lastServerUpdate
        }
        self.removed = removed
    }

    public func copy(uuid: String? = nil, refPrice: Float? = nil, refQuantity: Float? = nil, store: String? = nil, product: QuantifiableProduct? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> StoreProduct {
        return StoreProduct(
            uuid: uuid ?? self.uuid,
            refPrice: refPrice ?? self.refPrice.value,
            refQuantity: refQuantity ?? self.refQuantity.value,
            store: store ?? self.store,
            product: product ?? self.product.copy(),
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }

    public func totalPrice(quantity: Float) -> Float {
        return basePrice * quantity
    }

    // MARK: - Filters
    
    static func createFilter(_ uuid: String) -> NSPredicate {
        return NSPredicate(format: "uuid = %@", uuid)
    }

    static func createFilter(quantifiableProductUuids: [String]) -> NSPredicate {
        let uuidsStr: String = quantifiableProductUuids.map{"'\($0)'"}.joined(separator: ",")
        return NSPredicate(format: "productOpt.uuid IN {%@}", uuidsStr)
    }

    static func createFilterBrand(_ brand: String) -> NSPredicate {
        return NSPredicate(format: "productOpt.productOpt.brand = %@", brand)
    }
    
    static func createFilterStore(_ store: String) -> NSPredicate {
        return NSPredicate(format: "store = %@", store)
    }

    static func createFilterProduct(_ quantifiableProductUuid: String) -> NSPredicate {
        return NSPredicate(format: "productOpt.uuid = %@", quantifiableProductUuid)
    }

    static func createFilterProductStore(quantifiableProductUuid: String, store: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            createFilterProduct(quantifiableProductUuid),
            NSPredicate(format: "store = %@", store)
        ])
    }

    static func createFilterProductsStores(_ products: [QuantifiableProduct], store: String) -> NSPredicate {
        let productsUuidsStr: String = products.map{"'\($0.uuid)'"}.joined(separator: ",")
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "productOpt.uuid IN {%@}", productsUuidsStr),
            NSPredicate(format: "store = %@", store)
        ])
    }

    static func createFilterNameBrand(_ name: String, brand: String, store: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            createFilterName(name),
            createFilterBrand(brand),
            createFilterStore(store)
        ])
    }
    
    static func createFilterName(_ name: String) -> NSPredicate {
        return NSPredicate(format: "productOpt.productOpt.itemOpt.name = %@", name)
    }
    
    static func createFilterNameContains(_ text: String) -> NSPredicate {
        return NSPredicate(format: "productOpt.productOpt.itemOpt.name CONTAINS[c] %@", text)
    }
    
    static func createFilterBrandContains(_ text: String) -> NSPredicate {
        return NSPredicate(format: "productOpt.productOpt.brand CONTAINS[c] %@", text)
    }
    
    static func createFilterStoreContains(_ text: String) -> NSPredicate {
        return NSPredicate(format: "store CONTAINS[c] %@", text)
    }
    
    static func createFilterCategory(_ categoryUuid: String) -> NSPredicate {
        return NSPredicate(format: "productOpt.productOpt.categoryOpt.uuid = %@", categoryUuid)
    }
    
    static func createFilterCategoryNameContains(_ text: String) -> NSPredicate {
        return NSPredicate(format: "productOpt.productOpt.categoryOpt.name CONTAINS[c] %@", text)
    }
    
    static func createFilter(unique: QuantifiableProductUnique) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "productOpt.productOpt.itemOpt.name = %@", unique.name),
            NSPredicate(format: "productOpt.productOpt.brand = %@", unique.brand),
            NSPredicate(format: "productOpt.baseQuantity = %@", unique.baseQuantity),
            NSPredicate(format: "productOpt.unitOpt.name = %@", unique.unit),
            NSPredicate(format: "productOpt.secondBaseQuantity = %@", unique.secondBaseQuantity),
        ])
    }

    static func createFilter(unique: QuantifiableProductUnique, store: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            createFilter(unique: unique),
            createFilterStore(store)
        ])
    }

    // Sync - workaround for mysterious store products/products/categories that appear sometimes in sync reqeust
    // Note these invalid objects will be removed on sync response when db is overwritten
    public static func createFilterDirtyAndValid() -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            DBSyncable.dirtyFilter(),
            NSPredicate(format: "uuid != %@", "")
        ])
    }

    func toRealmMigrationDict(quantifiableProduct: QuantifiableProduct) -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid as AnyObject?
        dict["refPrice"] = refPrice as AnyObject?
        dict["refQuantity"] = refQuantity as AnyObject?
        dict["productOpt"] = quantifiableProduct
        return dict
    }

    // MARK: -
    
    static func fromDict(_ dict: [String: AnyObject], product: Product) -> StoreProduct {
        let item = StoreProduct()
        // Disabled because of structural changes (doesn't compile)
//        item.uuid = dict["uuid"]! as! String
//        item.price = dict["price"]! as! Float
//        item.product = product
//        item.baseQuantity = dict["baseQuantity"]! as! Float
//        item.unitVal = dict["unit"]! as! Int // TODO check that is valid enum val before assigning
//        item.store = dict["store"]! as! String
//        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        let dict = [String: AnyObject]()
        // Disabled because of structural changes (doesn't compile)
//        dict["uuid"] = uuid as AnyObject?
//        dict["price"] = price as AnyObject?
//        dict["baseQuantity"] = baseQuantity as AnyObject?
//        dict["unit"] = unit as AnyObject?
//        dict["store"] = store as AnyObject?
//        dict["product"] = product.toDict() as AnyObject?
//        setSyncableFieldsInDict(&dict)
        return dict
    }
    
    public override static func ignoredProperties() -> [String] {
        return ["product", "unit"]
    }
    
    // This function doesn't really have to here but don't have a better place yet
    // A key that can be used e.g. in dictionaries
    static func uniqueDictKey(_ name: String, brand: String, store: String, unit: Unit, baseQuantity: String) -> String {
        return name + "-.9#]A-\(brand)-.9#]A-\(store)-.9#]A-\(unit.name)-.9#]A-\(baseQuantity)" // insert some random text in between to prevent possible cases where name or brand text matches what would be a combination, e.g. a product is called "soapMyBrand" has empty brand and other product is called "soap" and has a brand "MyBrand" these are different but simple text concatenation would result in the same key.
    }
    
    override func deleteWithDependenciesSync(_ realm: Realm, markForSync: Bool) {
        _ = RealmStoreProductProvider().deleteStoreProductDependenciesSync(realm, storeProductUuid: uuid, markForSync: markForSync)
        realm.delete(self)
    }
    
    // MARK: -
    
    // Overwrite all fields with fields of storeProduct, except uuid
    public func update(_ storeProduct: StoreProduct) -> StoreProduct {
        return copy(storeProduct, product: storeProduct.product)
    }

    public func updateOnlyStoreAttributes(_ storeProductInput: StoreProductInput) -> StoreProduct {
        return copy(refPrice: storeProductInput.refPrice, refQuantity: storeProductInput.refQuantity)

    }

    // Updates self and its dependencies with storeProduct, the references to the dependencies (uuid) are not changed
    public func updateWithoutChangingReferences(_ storeProduct: StoreProduct) -> StoreProduct {
        let updatedProduct = product.updateWithoutChangingReferences(storeProduct.product)
        return update(storeProduct, product: updatedProduct)
    }

    fileprivate func update(_ storeProduct: StoreProduct, product: QuantifiableProduct) -> StoreProduct {
        return copy(refPrice: storeProduct.refPrice.value ?? 0, refQuantity: storeProduct.refQuantity.value ?? 0, store: storeProduct.store, product: product, lastServerUpdate: storeProduct.lastServerUpdate, removed: storeProduct.removed)
    }

    fileprivate func copy(_ storeProduct: StoreProduct, product: QuantifiableProduct) -> StoreProduct {
        return copy(refPrice: storeProduct.refPrice.value ?? 0, refQuantity: storeProduct.refQuantity.value ?? 0, store: storeProduct.store, product: product, lastServerUpdate: storeProduct.lastServerUpdate, removed: storeProduct.removed)
    }
    
    public func same(_ rhs: StoreProduct) -> Bool {
        return uuid == rhs.uuid
    }
    
    public var unique: StoreProductUnique {
        return (quantifiableProductUnique: product.unique, store: store)
    }
    
    public func matches(unique: StoreProductUnique) -> Bool {
        return store == unique.store && product.matches(unique: unique.quantifiableProductUnique)
    }
}

extension StoreProduct {
    
    static func createDefault(quantifiableProduct: QuantifiableProduct, store: String, refPrice: Float? = nil, refQuantity: Float? = nil) -> StoreProduct {
        return StoreProduct(
            uuid: UUID().uuidString,
            refPrice: refPrice ?? 0,
            refQuantity: refQuantity ?? 0,
            store: store,
            product: quantifiableProduct
        )
    }
}

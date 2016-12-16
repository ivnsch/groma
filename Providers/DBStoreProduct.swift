//
//  DBStoreProduct.swift
//  shoppin
//
//  Created by ischuetz on 07/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

public class DBStoreProduct: DBSyncable {
    
    public dynamic var uuid: String = ""
    public dynamic var price: Float = 0
    dynamic var productOpt: Product? = Product()
    public dynamic var baseQuantity: Float = 0
    public dynamic var unit: Int = 0
    public dynamic var store: String = ""
    
    public var product: Product {
        get {
            return productOpt ?? Product()
        }
        set(newProduct) {
            productOpt = newProduct
        }
    }
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public override class func indexedProperties() -> [String] {
        return ["name"]
    }
    
    public convenience init(uuid: String, price: Float, baseQuantity: Float, unit: Int, store: String = "", product: Product, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
        self.init()
        
        self.uuid = uuid
        self.price = price
        self.baseQuantity = baseQuantity
        self.unit = unit
        self.store = store
        self.product = product
        
        if let lastServerUpdate = lastServerUpdate {
            self.lastServerUpdate = lastServerUpdate
        }
        self.removed = removed
    }

    public func copy(uuid: String? = nil, price: Float? = nil, baseQuantity: Float? = nil, unit: Int? = nil, store: String? = nil, product: Product? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> DBStoreProduct {
        return DBStoreProduct(
            uuid: uuid ?? self.uuid,
            price: price ?? self.price,
            baseQuantity: baseQuantity ?? self.baseQuantity,
            unit: unit ?? self.unit,
            store: store ?? self.store,
            product: product ?? self.product,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    // MARK: - Filters
    
    static func createFilter(_ uuid: String) -> String {
        return "uuid == '\(uuid)'"
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
    
    static func createFilterProductStore(_ productUuid: String, store: String) -> String {
        return "\(createFilterProduct(productUuid)) && store == '\(store)'"
    }

    static func createFilterProductsStores(_ products: [Product], store: String) -> String {
        let productsUuidsStr: String = products.map{"'\($0.uuid)'"}.joined(separator: ",")
        return "productOpt.uuid IN {\(productsUuidsStr)} && store == '\(store)'"
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
    
    // Sync - workaround for mysterious store products/products/categories that appear sometimes in sync reqeust
    // Note these invalid objects will be removed on sync response when db is overwritten
    public static func createFilterDirtyAndValid() -> String {
        return "\(DBSyncable.dirtyFilter()) && uuid != ''"
    }

    // MARK: -
    
    static func fromDict(_ dict: [String: AnyObject], product: Product) -> DBStoreProduct {
        let item = DBStoreProduct()
        item.uuid = dict["uuid"]! as! String
        item.price = dict["price"]! as! Float
        item.product = product
        item.baseQuantity = dict["baseQuantity"]! as! Float
        item.unit = dict["unit"]! as! Int
        item.store = dict["store"]! as! String
        item.setSyncableFieldswithRemoteDict(dict)
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid as AnyObject?
        dict["price"] = price as AnyObject?
        dict["baseQuantity"] = baseQuantity as AnyObject?
        dict["unit"] = unit as AnyObject?
        dict["store"] = store as AnyObject?
        dict["product"] = product.toDict() as AnyObject?
        setSyncableFieldsInDict(&dict)
        return dict
    }
    
    public override static func ignoredProperties() -> [String] {
        return ["product"]
    }
    
    // This function doesn't really have to here but don't have a better place yet
    // A key that can be used e.g. in dictionaries
    static func nameBrandStoreKey(_ name: String, brand: String, store: String) -> String {
        return name + "-.9#]A-" + brand + "-.9#]A-" + store // insert some random text in between to prevent possible cases where name or brand text matches what would be a combination, e.g. a product is called "soapMyBrand" has empty brand and other product is called "soap" and has a brand "MyBrand" these are different but simple text concatenation would result in the same key.
    }
    
    override func deleteWithDependenciesSync(_ realm: Realm, markForSync: Bool) {
        _ = RealmStoreProductProvider().deleteStoreProductDependenciesSync(realm, storeProductUuid: uuid, markForSync: markForSync)
        realm.delete(self)
    }
}

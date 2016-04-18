//
//  DBStoreProduct.swift
//  shoppin
//
//  Created by ischuetz on 07/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBStoreProduct: DBSyncable {
    
    dynamic var uuid: String = ""
    dynamic var price: Float = 0
    dynamic var productOpt: DBProduct? = DBProduct()
    dynamic var baseQuantity: Float = 0
    dynamic var unit: Int = 0
    dynamic var store: String = ""
    
    var product: DBProduct {
        get {
            return productOpt ?? DBProduct()
        }
        set(newProduct) {
            productOpt = newProduct
        }
    }
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    override class func indexedProperties() -> [String] {
        return ["name"]
    }
    
    convenience init(uuid: String, price: Float, baseQuantity: Float, unit: Int, store: String = "", product: DBProduct, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
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

    func copy(uuid uuid: String? = nil, price: Float? = nil, baseQuantity: Float? = nil, unit: Int? = nil, product: DBProduct? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> DBStoreProduct {
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
    
    static func createFilter(uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilterBrand(brand: String) -> String {
        return "productOpt.brand == '\(brand)'"
    }
    
    static func createFilterStore(store: String) -> String {
        return "store == '\(store)'"
    }

    static func createFilterProduct(productUuid: String) -> String {
        return "productOpt.uuid == '\(productUuid)'"
    }
    
    static func createFilterProductStore(productUuid: String, store: String) -> String {
        return "\(createFilterProduct(productUuid)) && store == '\(store)'"
    }

    static func createFilterProductsStores(products: [Product], store: String) -> String {
        let productsUuidsStr: String = products.map{"'\($0.uuid)'"}.joinWithSeparator(",")
        return "productOpt.uuid IN {\(productsUuidsStr)} && store == '\(store)'"
    }
    
//    static func createFilterUnique(prototype: ProductPrototype) -> String {
//        return createFilterNameBrand(prototype.name, brand: prototype.brand, store: prototype.store)
//    }
    
    static func createFilterNameBrand(name: String, brand: String, store: String) -> String {
        return "\(createFilterName(name)) AND \(createFilterBrand(brand)) AND \(createFilterStore(store))"
    }
    
    static func createFilterName(name: String) -> String {
        return "productOpt.name = '\(name)'"
    }
    
    static func createFilterNameContains(text: String) -> String {
        return "productOpt.name CONTAINS[c] '\(text)'"
    }
    
    static func createFilterBrandContains(text: String) -> String {
        return "productOpt.brand CONTAINS[c] '\(text)'"
    }
    
    static func createFilterStoreContains(text: String) -> String {
        return "store CONTAINS[c] '\(text)'"
    }
    
    static func createFilterCategory(categoryUuid: String) -> String {
        return "productOpt.categoryOpt.uuid = '\(categoryUuid)'"
    }
    
    static func createFilterCategoryNameContains(text: String) -> String {
        return "productOpt.categoryOpt.name CONTAINS[c] '\(text)'"
    }

    // MARK: -
    
    static func fromDict(dict: [String: AnyObject], product: DBProduct) -> DBStoreProduct {
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
        dict["uuid"] = uuid
        dict["price"] = price
        dict["baseQuantity"] = baseQuantity
        dict["unit"] = unit
        dict["store"] = store
        dict["product"] = product.toDict()
        setSyncableFieldsInDict(&dict)
        return dict
    }
    
    override static func ignoredProperties() -> [String] {
        return ["product"]
    }
    
    // This function doesn't really have to here but don't have a better place yet
    // A key that can be used e.g. in dictionaries
    static func nameBrandStoreKey(name: String, brand: String, store: String) -> String {
        return name + "-.9#]A-" + brand + "-.9#]A-" + store // insert some random text in between to prevent possible cases where name or brand text matches what would be a combination, e.g. a product is called "soapMyBrand" has empty brand and other product is called "soap" and has a brand "MyBrand" these are different but simple text concatenation would result in the same key.
    }
}

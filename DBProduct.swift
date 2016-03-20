//
//  DBProduct.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBProduct: DBSyncable {
    
    dynamic var uuid: String = ""
    dynamic var name: String = ""
    dynamic var price: Float = 0
    dynamic var categoryOpt: DBProductCategory? = DBProductCategory()
    dynamic var baseQuantity: Float = 0
    dynamic var unit: Int = 0
    dynamic var fav: Int = 0
    dynamic var brand: String = ""
    dynamic var store: String = ""
    
    var category: DBProductCategory {
        get {
            return categoryOpt ?? DBProductCategory()
        }
        set(newCategory) {
            categoryOpt = newCategory
        }
    }
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    override class func indexedProperties() -> [String] {
        return ["name"]
    }
    
    convenience init(uuid: String, name: String, price: Float, category: DBProductCategory, baseQuantity: Float, unit: Int, fav: Int = 0, brand: String = "", store: String = "", lastUpdate: NSDate = NSDate(), lastServerUpdate: NSDate? = nil, removed: Bool = false) {
        
        self.init()
        
        self.uuid = uuid
        self.name = name
        self.price = price
        self.category = category
        self.baseQuantity = baseQuantity
        self.unit = unit
        self.fav = fav
        self.brand = brand
        self.store = store
        
        self.lastUpdate = lastUpdate
        if let lastServerUpdate = lastServerUpdate {
            self.lastServerUpdate = lastServerUpdate
        }
        self.removed = removed
    }
    
    convenience init(prototype: ProductPrototype, category: DBProductCategory) {
        self.init(
            uuid: NSUUID().UUIDString,
            name: prototype.name,
            price: prototype.price,
            category: category,
            baseQuantity: prototype.baseQuantity,
            unit: prototype.unit.rawValue,
            fav: 0,
            brand: prototype.brand,
            store: prototype.store
        )
    }
    
    func copy(uuid uuid: String? = nil, name: String? = nil, price: Float? = nil, category: DBProductCategory? = nil, baseQuantity: Float? = nil, unit: Int? = nil, fav: Int? = nil, brand: String? = nil, store: String? = nil, lastUpdate: NSDate? = nil, lastServerUpdate: NSDate? = nil, removed: Bool? = nil) -> DBProduct {
        return DBProduct(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            price: price ?? self.price,
            category: category ?? self.category,
            baseQuantity: baseQuantity ?? self.baseQuantity,
            unit: unit ?? self.unit,
            fav: fav ?? self.fav,
            brand: brand ?? self.brand,
            store: store ?? self.store,
            lastUpdate: lastUpdate ?? self.lastUpdate,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    // Overwrites fields with corresponding fields of prototype.
    // NOTE: Does not update category fields.
    func update(prototype: ProductPrototype) -> DBProduct {
        return copy(name: prototype.name, price: prototype.price, baseQuantity: prototype.baseQuantity, unit: prototype.unit.rawValue, brand: prototype.brand, store: prototype.store)
    }
    
    // MARK: - Filters
    
    static func createFilter(uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilterBrand(brand: String) -> String {
        return "brand == '\(brand)'"
    }
    
    static func createFilterStore(store: String) -> String {
        return "store == '\(store)'"
    }
    
    static func createFilterUnique(prototype: ProductPrototype) -> String {
        return createFilterNameBrand(prototype.name, brand: prototype.brand, store: prototype.store)
    }
    
    static func createFilterNameBrand(name: String, brand: String, store: String) -> String {
        return "\(createFilterName(name)) AND \(createFilterBrand(brand)) AND \(createFilterStore(store))"
    }
    
    static func createFilterName(name: String) -> String {
        return "name = '\(name)'"
    }
    
    static func createFilterNameContains(text: String) -> String {
        return "name CONTAINS[c] '\(text)'"
    }
    
    static func createFilterBrandContains(text: String) -> String {
        return "brand CONTAINS[c] '\(text)'"
    }
    
    static func createFilterStoreContains(text: String) -> String {
        return "store CONTAINS[c] '\(text)'"
    }
    
    static func createFilterCategory(categoryUuid: String) -> String {
        return "categoryOpt.uuid = '\(categoryUuid)'"
    }
    
    static func createFilterCategoryNameContains(text: String) -> String {
        return "categoryOpt.name CONTAINS[c] '\(text)'"
    }
    
    // MARK: -
    
    static func fromDict(dict: [String: AnyObject], category: DBProductCategory) -> DBProduct {
        let item = DBProduct()
        item.uuid = dict["uuid"]! as! String
        item.name = dict["name"]! as! String
        item.price = dict["price"]! as! Float
        item.category = category
        item.baseQuantity = dict["baseQuantity"]! as! Float
        item.unit = dict["unit"]! as! Int
        item.fav = dict["fav"]! as! Int
        item.brand = dict["brand"]! as! String
        item.store = dict["store"]! as! String
        item.setSyncableFieldswithRemoteDict(dict)        
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid
        dict["name"] = name
        dict["price"] = price
        dict["category"] = category.toDict()
        dict["baseQuantity"] = baseQuantity
        dict["unit"] = unit
        dict["fav"] = fav
        dict["brand"] = brand
        dict["store"] = store
        setSyncableFieldsInDict(dict)
        return dict
    }
    
    // This function doesn't really have to here but don't have a better place yet
    // A key that can be used e.g. in dictionaries
    static func nameBrandKey(name: String, brand: String) -> String {
        return name + "-.9#]A-" + brand // insert some random text in between to prevent possible cases where name or brand text matches what would be a combination, e.g. a product is called "soapMyBrand" has empty brand and other product is called "soap" and has a brand "MyBrand" these are different but simple text concatenation would result in the same key.
    }

    override static func ignoredProperties() -> [String] {
        return ["category"]
    }
}

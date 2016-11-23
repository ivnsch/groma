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
    dynamic var categoryOpt: DBProductCategory? = DBProductCategory()
    dynamic var fav: Int = 0
    dynamic var brand: String = ""
    
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
    
    convenience init(uuid: String, name: String, category: DBProductCategory, fav: Int = 0, brand: String = "", lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
        self.init()
        
        self.uuid = uuid
        self.name = name
        self.category = category
        self.fav = fav
        self.brand = brand
        
        if let lastServerUpdate = lastServerUpdate {
            self.lastServerUpdate = lastServerUpdate
        }
        self.removed = removed
    }
    
    convenience init(prototype: ProductPrototype, category: DBProductCategory) {
        self.init(
            uuid: UUID().uuidString,
            name: prototype.name,
            category: category,
            fav: 0,
            brand: prototype.brand
        )
    }
    
    func copy(uuid: String? = nil, name: String? = nil, category: DBProductCategory? = nil, fav: Int? = nil, brand: String? = nil, store: String? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> DBProduct {
        return DBProduct(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            category: category ?? self.category,
            fav: fav ?? self.fav,
            brand: brand ?? self.brand,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    // Overwrites fields with corresponding fields of prototype.
    // NOTE: Does not update category fields.
    func update(_ prototype: ProductPrototype) -> DBProduct {
        return copy(name: prototype.name, brand: prototype.brand)
    }
    
    // MARK: - Filters
    
    static func createFilter(_ uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilterBrand(_ brand: String) -> String {
        return "brand == '\(brand)'"
    }
    
    static func createFilterUnique(_ prototype: ProductPrototype) -> String {
        return createFilterNameBrand(prototype.name, brand: prototype.brand)
    }
    
    static func createFilterNameBrand(_ name: String, brand: String) -> String {
        return "\(createFilterName(name)) AND \(createFilterBrand(brand))"
    }
    
    static func createFilterName(_ name: String) -> String {
        return "name = '\(name)'"
    }
    
    static func createFilterNameContains(_ text: String) -> String {
        return "name CONTAINS[c] '\(text)'"
    }
    
    static func createFilterBrandContains(_ text: String) -> String {
        return "brand CONTAINS[c] '\(text)'"
    }
    
    static func createFilterStoreContains(_ text: String) -> String {
        return "store CONTAINS[c] '\(text)'"
    }
    
    static func createFilterCategory(_ categoryUuid: String) -> String {
        return "categoryOpt.uuid = '\(categoryUuid)'"
    }
    
    static func createFilterCategoryNameContains(_ text: String) -> String {
        return "categoryOpt.name CONTAINS[c] '\(text)'"
    }
    
    // Sync - workaround for mysterious store products/products/categories that appear sometimes in sync reqeust
    // Note these invalid objects will be removed on sync response when db is overwritten
    static func createFilterDirtyAndValid() -> String {
        return "\(DBSyncable.dirtyFilter()) && uuid != ''"
    }
    
    // MARK: -
    
    static func fromDict(_ dict: [String: AnyObject], category: DBProductCategory) -> DBProduct {
        let item = DBProduct()
        item.uuid = dict["uuid"]! as! String
        item.name = dict["name"]! as! String
        item.category = category
        item.fav = dict["fav"]! as! Int
        item.brand = dict["brand"]! as! String
        item.setSyncableFieldswithRemoteDict(dict)        
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid as AnyObject?
        dict["name"] = name as AnyObject?
        dict["category"] = category.toDict() as AnyObject?
        dict["fav"] = fav as AnyObject?
        dict["brand"] = brand as AnyObject?
        setSyncableFieldsInDict(&dict)
        return dict
    }
    
    // This function doesn't really have to here but don't have a better place yet
    // A key that can be used e.g. in dictionaries
    static func nameBrandKey(_ name: String, brand: String) -> String {
        return name + "-.9#]A-" + brand // insert some random text in between to prevent possible cases where name or brand text matches what would be a combination, e.g. a product is called "soapMyBrand" has empty brand and other product is called "soap" and has a brand "MyBrand" these are different but simple text concatenation would result in the same key.
    }

    override static func ignoredProperties() -> [String] {
        return ["category"]
    }

    override func deleteWithDependenciesSync(_ realm: Realm, markForSync: Bool) {
        _ = DBProviders.productProvider.deleteProductDependenciesSync(realm, productUuid: uuid, markForSync: markForSync)
        realm.delete(self)
    }
}

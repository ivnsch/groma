//
//  Product.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift


enum ProductUnit: Int {
    case none = 0
    case gram = 1
    case kilogram = 2

    var text: String {
        switch self {
        case .none: return "None"
        case .gram: return "Gram"
        case .kilogram: return "Kilogram"
        }
    }

    var shortText: String {
        switch self {
        case .none: return ""
        case .gram: return "g"
        case .kilogram: return "kg"
        }
    }
}


class Product: DBSyncable, Identifiable {
    
    dynamic var uuid: String = ""
    dynamic var name: String = ""
    dynamic var categoryOpt: ProductCategory? = ProductCategory()
    dynamic var fav: Int = 0
    dynamic var brand: String = ""
    
    var category: ProductCategory {
        get {
            return categoryOpt ?? ProductCategory()
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
    
    convenience init(uuid: String, name: String, category: ProductCategory, fav: Int = 0, brand: String = "", lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
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
    
    convenience init(prototype: ProductPrototype, category: ProductCategory) {
        self.init(
            uuid: UUID().uuidString,
            name: prototype.name,
            category: category,
            fav: 0,
            brand: prototype.brand
        )
    }
    
    func copy(uuid: String? = nil, name: String? = nil, category: ProductCategory? = nil, fav: Int? = nil, brand: String? = nil, store: String? = nil, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> Product {
        return Product(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            category: category ?? self.category.copy(),
            fav: fav ?? self.fav,
            brand: brand ?? self.brand,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    // Overwrites fields with corresponding fields of prototype.
    // NOTE: Does not update category fields.
    func update(_ prototype: ProductPrototype) -> Product {
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
    
    static func createFilterUuids(_ uuids: [String]) -> String {
        let uuidsStr: String = uuids.map{"'\($0)'"}.joined(separator: ",")
        return "uuid IN {\(uuidsStr)}"
    }
    
    // Sync - workaround for mysterious store products/products/categories that appear sometimes in sync reqeust
    // Note these invalid objects will be removed on sync response when db is overwritten
    static func createFilterDirtyAndValid() -> String {
        return "\(DBSyncable.dirtyFilter()) && uuid != ''"
    }
    
    // MARK: -
    
    static func fromDict(_ dict: [String: AnyObject], category: ProductCategory) -> Product {
        let item = Product()
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
    
    
    // MARK: -

    func update(_ product: Product) -> Product {
        return update(product, category: product.category)
    }

    // Updates self and its dependencies with product, the references to the dependencies (uuid) are not changed
    func updateWithoutChangingReferences(_ product: Product) -> Product {
        let updatedCategory = category.updateWithoutChangingReferences(product.category)
        return update(product, category: updatedCategory)
    }

    fileprivate func update(_ product: Product, category: ProductCategory) -> Product {
        return copy(name: product.name, category: product.category, fav: product.fav, brand: product.brand, lastServerUpdate: product.lastServerUpdate, removed: product.removed)
    }

    func same(_ rhs: Product) -> Bool {
        return uuid == rhs.uuid
    }
}

func ==(lhs: Product, rhs: Product) -> Bool {
    return lhs.uuid == rhs.uuid && lhs.name == rhs.name && lhs.category == rhs.category && lhs.brand == rhs.brand && lhs.lastServerUpdate == rhs.lastServerUpdate && lhs.removed == rhs.removed
}

// TODO REMOVE?
// convenience (redundant) holder to avoid having to iterate through listitems to find unique categories
typealias ProductsWithDependencies = (products: [Product], categories: [ProductCategory])

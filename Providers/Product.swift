//
//  Product.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

public class Product: DBSyncable, Identifiable {
    
    public dynamic var uuid: String = ""
    dynamic var itemOpt: Item? = Item()
    public dynamic var brand: String = ""
    public dynamic var fav: Int = 0
    
    public var item: Item {
        get {
            return itemOpt ?? Item()
        }
        set(newItem) {
            itemOpt = newItem
        }
    }

    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public override class func indexedProperties() -> [String] {
        return ["name"]
    }
    
    /// Convenience initializer that creates Item, using name. This is only for the items we add in the pre-filler, to not have to edit everything to add Item(...).
    public convenience init(uuid: String, name: String, category: ProductCategory, brand: String = "", fav: Int = 0, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
        self.init()
        
        self.uuid = uuid
        self.item = Item(uuid: UUID().uuidString, name: name, category: category, fav: 0)
        self.brand = brand
        
        if let lastServerUpdate = lastServerUpdate {
            self.lastServerUpdate = lastServerUpdate
        }
        self.removed = removed
    }
    
    
    public convenience init(uuid: String, item: Item, brand: String = "", fav: Int = 0, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
        self.init()
        
        self.uuid = uuid
        self.item = item
        self.brand = brand
        
        if let lastServerUpdate = lastServerUpdate {
            self.lastServerUpdate = lastServerUpdate
        }
        self.removed = removed
    }
    
    public convenience init(prototype: ProductPrototype, item: Item) {
        self.init(
            uuid: UUID().uuidString,
            item: item,
            brand: prototype.brand
        )
    }
    
    public func copy(uuid: String? = nil, item: Item? = nil, brand: String? = nil, store: String? = nil, fav: Int? = 0, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> Product {
        return Product(
            uuid: uuid ?? self.uuid,
            item: item ?? self.item.copy(),
            brand: brand ?? self.brand,
            fav: fav ?? self.fav,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }

//    // Overwrites fields with corresponding fields of prototype.
//    // NOTE: Does not update category fields.
//    public func update(_ prototype: ProductPrototype) -> Product {
//        return copy(name: prototype.name, brand: prototype.brand)
//    }

    // MARK: - Filters
    
    static func createFilter(_ uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilterBrand(_ brand: String) -> String {
        return "brand == '\(brand)'"
    }
    
    static func createFilter(unique: ProductUnique) -> String {
        return createFilterNameBrand(unique.name, brand: unique.brand)
    }
    
    static func createFilterNameBrand(_ name: String, brand: String) -> String {
        return "\(createFilterName(name)) AND \(createFilterBrand(brand))"
    }
    
    static func createFilterName(_ name: String) -> String {
        return "itemOpt.name = '\(name)'"
    }
    
    static func createFilter(base: String) -> String {
        return "baseQuantity = '\(base)'"
    }
    
    static func createFilterNameContains(_ text: String) -> String {
        return "itemOpt.name CONTAINS[c] '\(text)'"
    }
    
    static func createFilterBrandContains(_ text: String) -> String {
        return "brand CONTAINS[c] '\(text)'"
    }
    
    static func createFilterStoreContains(_ text: String) -> String {
        return "store CONTAINS[c] '\(text)'"
    }
    
    static func createFilterCategory(_ categoryUuid: String) -> String {
        return "itemOpt.categoryOpt.uuid = '\(categoryUuid)'"
    }
    
    static func createFilterCategoryNameContains(_ text: String) -> String {
        return "itemOpt.categoryOpt.name CONTAINS[c] '\(text)'"
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
//        item.name = dict["name"]! as! String
//        item.category = category
//        item.fav = dict["fav"]! as! Int
        item.brand = dict["brand"]! as! String
        item.setSyncableFieldswithRemoteDict(dict)        
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid as AnyObject?
//        dict["name"] = name as AnyObject?
//        dict["category"] = category.toDict() as AnyObject?
//        dict["fav"] = fav as AnyObject?
        dict["brand"] = brand as AnyObject?
        setSyncableFieldsInDict(&dict)
        return dict
    }
    
    // This function doesn't really have to here but don't have a better place yet
    // A key that can be used e.g. in dictionaries
    static func nameBrandKey(_ name: String, brand: String) -> String {
        return name + "-.9#]A-" + brand // insert some random text in between to prevent possible cases where name or brand text matches what would be a combination, e.g. a product is called "soapMyBrand" has empty brand and other product is called "soap" and has a brand "MyBrand" these are different but simple text concatenation would result in the same key.
    }

    public override static func ignoredProperties() -> [String] {
        return ["item"]
    }

    override func deleteWithDependenciesSync(_ realm: Realm, markForSync: Bool) {
        _ = DBProv.productProvider.deleteProductDependenciesSync(realm, productUuid: uuid, markForSync: markForSync)
        realm.delete(self)
    }
    
    
    // MARK: -

    public func update(_ product: Product) -> Product {
        return update(product, item: product.item)
    }
    
    // Updates product properties that don't belong to its unique with prototype
    public func updateNonUniqueProperties(prototype: ProductPrototype) -> Product {
        let updatedItem = item.updateNonUniqueProperties(prototype: prototype)
        return copy(item: item)
    }

    // Updates self and its dependencies with product, the references to the dependencies (uuid) are not changed
    public func updateWithoutChangingReferences(_ product: Product) -> Product {
        let updatedItem = item.updateWithoutChangingReferences(product.item)
        return update(product, item: updatedItem)
    }

    fileprivate func update(_ product: Product, item: Item) -> Product {
        return copy(item: item, brand: product.brand, lastServerUpdate: product.lastServerUpdate, removed: product.removed)
    }

    public func same(_ rhs: Product) -> Bool {
        return uuid == rhs.uuid
    }
}

public func ==(lhs: Product, rhs: Product) -> Bool {
    return lhs.uuid == rhs.uuid && lhs.item == rhs.item && lhs.brand == rhs.brand && lhs.lastServerUpdate == rhs.lastServerUpdate && lhs.removed == rhs.removed
}

// TODO REMOVE?
// convenience (redundant) holder to avoid having to iterate through listitems to find unique categories
public typealias ProductsWithDependencies = (products: [Product], categories: [ProductCategory])

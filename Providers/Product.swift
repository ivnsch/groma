//
//  Product.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift


public enum ProductUnit: Int {
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
    
    public static func fromString(_ string: String) -> ProductUnit? {
        switch string {
        case "": return ProductUnit.none // note prefix otherwise it's processed as Option.none
        case "g": return .gram
        case "kg": return .kilogram
        default: return nil
        }
    }
}


public class Product: DBSyncable, Identifiable {
    
    public dynamic var uuid: String = ""
    public dynamic var name: String = ""
    dynamic var categoryOpt: ProductCategory? = ProductCategory()
    public dynamic var brand: String = ""
    public dynamic var fav: Int = 0
    
    public var category: ProductCategory {
        get {
            return categoryOpt ?? ProductCategory()
        }
        set(newCategory) {
            categoryOpt = newCategory
        }
    }
    
    public override static func primaryKey() -> String? {
        return "uuid"
    }
    
    public override class func indexedProperties() -> [String] {
        return ["name"]
    }
    
    public convenience init(uuid: String, name: String, category: ProductCategory, brand: String = "", fav: Int = 0, lastServerUpdate: Int64? = nil, removed: Bool = false) {
        
        self.init()
        
        self.uuid = uuid
        self.name = name
        self.category = category
        self.brand = brand
        
        if let lastServerUpdate = lastServerUpdate {
            self.lastServerUpdate = lastServerUpdate
        }
        self.removed = removed
    }
    
    public convenience init(prototype: ProductPrototype, category: ProductCategory) {
        self.init(
            uuid: UUID().uuidString,
            name: prototype.name,
            category: category,
            brand: prototype.brand
        )
    }
    
    public func copy(uuid: String? = nil, name: String? = nil, category: ProductCategory? = nil, brand: String? = nil, store: String? = nil, fav: Int = 0, lastServerUpdate: Int64? = nil, removed: Bool? = nil) -> Product {
        return Product(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name,
            category: category ?? self.category.copy(),
            brand: brand ?? self.brand,
            fav: fav ?? self.fav,
            lastServerUpdate: lastServerUpdate ?? self.lastServerUpdate,
            removed: removed ?? self.removed
        )
    }
    
    // Overwrites fields with corresponding fields of prototype.
    // NOTE: Does not update category fields.
    public func update(_ prototype: ProductPrototype) -> Product {
        return copy(name: prototype.name, brand: prototype.brand)
    }
    
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
        return "name = '\(name)'"
    }
    
    static func createFilter(base: String) -> String {
        return "baseQuantity = '\(base)'"
    }

    static func createFilter(unit: ProductUnit) -> String {
        return "unitVal = '\(unit.rawValue)'"
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
//        item.fav = dict["fav"]! as! Int
        item.brand = dict["brand"]! as! String
        item.setSyncableFieldswithRemoteDict(dict)        
        return item
    }
    
    func toDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["uuid"] = uuid as AnyObject?
        dict["name"] = name as AnyObject?
        dict["category"] = category.toDict() as AnyObject?
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
        return ["category"]
    }

    override func deleteWithDependenciesSync(_ realm: Realm, markForSync: Bool) {
        _ = DBProv.productProvider.deleteProductDependenciesSync(realm, productUuid: uuid, markForSync: markForSync)
        realm.delete(self)
    }
    
    
    // MARK: -

    public func update(_ product: Product) -> Product {
        return update(product, category: product.category)
    }
    
    // Updates product properties that don't belong to its unique with prototype
    public func updateNonUniqueProperties(prototype: ProductPrototype) -> Product {
        let updatedCateogry = category.copy(name: prototype.category, color: prototype.categoryColor)
        return copy(category: updatedCateogry)
    }

    // Updates self and its dependencies with product, the references to the dependencies (uuid) are not changed
    public func updateWithoutChangingReferences(_ product: Product) -> Product {
        let updatedCategory = category.updateWithoutChangingReferences(product.category)
        return update(product, category: updatedCategory)
    }

    fileprivate func update(_ product: Product, category: ProductCategory) -> Product {
        return copy(name: product.name, category: product.category, brand: product.brand, lastServerUpdate: product.lastServerUpdate, removed: product.removed)
    }

    public func same(_ rhs: Product) -> Bool {
        return uuid == rhs.uuid
    }
}

public func ==(lhs: Product, rhs: Product) -> Bool {
    return lhs.uuid == rhs.uuid && lhs.name == rhs.name && lhs.category == rhs.category && lhs.brand == rhs.brand && lhs.lastServerUpdate == rhs.lastServerUpdate && lhs.removed == rhs.removed
}

// TODO REMOVE?
// convenience (redundant) holder to avoid having to iterate through listitems to find unique categories
public typealias ProductsWithDependencies = (products: [Product], categories: [ProductCategory])

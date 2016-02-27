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
    
    // MARK: - Filters
    
    static func createFilter(uuid: String) -> String {
        return "uuid == '\(uuid)'"
    }
    
    static func createFilterBrand(brand: String) -> String {
        return "brand == '\(brand)'"
    }
    
    static func createFilterNameBrand(name: String, brand: String) -> String {
        return "\(createFilterName(name)) AND \(createFilterBrand(brand))"
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

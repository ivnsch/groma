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
    dynamic var category: DBProductCategory = DBProductCategory()
    dynamic var baseQuantity: Float = 0
    dynamic var unit: Int = 0
    dynamic var fav: Int = 0
    dynamic var brand: String = ""
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
    override class func indexedProperties() -> [String] {
        return ["name"]
    }
    
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
}

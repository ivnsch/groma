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
}

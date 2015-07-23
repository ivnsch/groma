//
//  DBInventoryItem.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBInventoryItem: Object {
    
    dynamic var id: Int = 0
    dynamic var quantity: Int = 0
    dynamic var product: DBProduct = DBProduct()
    dynamic var inventory: DBInventory = DBInventory()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}


//
//  DBInventoryItem.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class DBInventoryItem: DBSyncable {
    
    dynamic var quantity: Int = 0
    dynamic var quantityDelta: Int = 0
    dynamic var product: DBProduct = DBProduct()
    dynamic var inventory: DBInventory = DBInventory()
    
    dynamic lazy var compoundKey: String = self.compoundKeyValue()

    private func compoundKeyValue() -> String {
        return "\(product.uuid)-\(inventory.uuid)"
    }

    override static func primaryKey() -> String? {
        return "compoundKey"
    }
}


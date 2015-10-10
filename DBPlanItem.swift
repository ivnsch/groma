//
//  DBPlanItem.swift
//  shoppin
//
//  Created by ischuetz on 07/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class DBPlanItem: DBSyncable {
    
    dynamic var inventory: DBInventory = DBInventory()
    dynamic var product: DBProduct = DBProduct()
    dynamic var quantity: Int = 0
    dynamic var quantityDelta: Int = 0
    
    dynamic lazy var key: String = self.keyValue()
    
    private func keyValue() -> String {
        return product.uuid
    }
    
    override static func primaryKey() -> String? {
        return "key"
    }
}
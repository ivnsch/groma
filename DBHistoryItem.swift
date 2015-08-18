//
//  DBHistoryItem.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class DBHistoryItem: DBSyncable {

    dynamic var uuid: String = ""
    dynamic var inventory: DBInventory = DBInventory()
    dynamic var product: DBProduct = DBProduct()
    dynamic var addedDate: NSDate = NSDate()
    dynamic var quantity: Int = 0
    dynamic var user: DBSharedUser = DBSharedUser()
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
}
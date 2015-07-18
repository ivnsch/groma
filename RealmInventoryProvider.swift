//
//  RealmInventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class RealmInventoryProvider: RealmProvider {
   
    let dbListItemProvider: RealmListItemProvider = RealmListItemProvider()
    
    func loadInventory(handler: [DBInventoryItem] -> ()) {
        var dbObjs: Results<DBInventoryItem> = Realm().objects(DBInventoryItem)
        handler(dbObjs.toArray())
    }
    
    func saveInventory(items: [InventoryItem], handler: Bool -> ()) {
        let dbObjs = items.map{InventoryItemMapper.dbWithInventoryItem($0)}
        self.saveObjs(dbObjs, update: true, handler: handler)
    }
}

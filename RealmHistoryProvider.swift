//
//  RealmHistoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class RealmHistoryProvider: RealmProvider {

    func add(historyItem: HistoryItem, handler: Bool -> ()) {
        let dbObj = HistoryItemMapper.dbWithHistoryItem(historyItem)
        self.saveObj(dbObj, update: false, handler: handler)
    }
    
    func loadHistoryItems(handler: [HistoryItem] -> ()) {
        let mapper = {HistoryItemMapper.historyItemWith($0)} // TODO loading shared users (when there are shared users) when accessing, crash: BAD_ACCESS, re-test after realm update
        self.load(mapper, handler: handler)
    }

    func loadHistoryItems(startDate: NSDate, handler: [HistoryItem] -> ()) {
        let mapper = {HistoryItemMapper.historyItemWith($0)} // TODO loading shared users (when there are shared users) when accessing, crash: BAD_ACCESS, re-test after realm update
        self.load(mapper, predicate: NSPredicate(format: "addedDate >= %@", startDate), handler: handler)
    }
    
    func saveHistoryItems(historyItems: RemoteHistoryItems, handler: Bool -> ()) {
        
        self.doInWriteTransaction({realm in
            
            realm.delete(realm.objects(DBInventoryItem))
            
            // save inventory items
            let historyItemsWithRelations = HistoryItemMapper.historyItemsWithRemote(historyItems)
            
            for inventory in historyItemsWithRelations.inventories {
                let dbInventory = InventoryMapper.dbWithInventory(inventory)
                realm.add(dbInventory, update: true) // since we don't delete products (see comment above) we do update
            }
            
            for product in historyItemsWithRelations.products {
                let dbProduct = ProductMapper.dbWithProduct(product)
                realm.add(dbProduct, update: true) // since we don't delete products (see comment above) we do update
            }
            
            for user in historyItemsWithRelations.users {
                let dbUser = SharedUserMapper.dbWithSharedUser(user)
                realm.add(dbUser, update: true)
            }
            
            for historyItem in historyItemsWithRelations.historyItems {
                let dbInventoryItem = HistoryItemMapper.dbWithHistoryItem(historyItem)
                realm.add(dbInventoryItem, update: true)
            }
            
            return true
            
            }, finishHandler: {success in
                handler(success)
            }
        )
    }
    
    func saveHistoryItemsSyncResult(historyItems: RemoteHistoryItems, handler: Bool -> ()) {
        self.saveHistoryItems(historyItems, handler: handler)
    }
}
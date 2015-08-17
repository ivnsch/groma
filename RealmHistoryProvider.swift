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
        let mapper = {HistoryItemMapper.historyItemWith($0)}
        self.load(mapper, handler: handler)
    }
    
    func saveHistoryItemsSyncResult(historyItems: RemoteHistoryItems, handler: Bool -> ()) {
        
        self.doInWriteTransaction({realm in
            
            realm.delete(realm.objects(DBInventoryItem))
            
            // save inventory items
            let historyItemsWithRelations = HistoryItemMapper.historyItemsWithRemote(historyItems)
        
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
                realm.add(dbInventoryItem, update: false)
            }

            return true
            
            }, finishHandler: {success in
                handler(success)
            }
        )
    }
}
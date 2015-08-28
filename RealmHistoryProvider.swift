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

    private lazy var historySortDescriptor: NSSortDescriptor = NSSortDescriptor(key: "addedDate", ascending: false)
    
    func add(historyItem: HistoryItem, handler: Bool -> ()) {
        let dbObj = HistoryItemMapper.dbWithHistoryItem(historyItem)
        self.saveObj(dbObj, update: false, handler: handler)
    }
    
    func loadHistoryItems(range: NSRange? = nil, handler: [HistoryItem] -> ()) {
        let mapper = {HistoryItemMapper.historyItemWith($0)} // TODO loading shared users (when there are shared users) when accessing, crash: BAD_ACCESS, re-test after realm update
        self.load(mapper, sortDescriptor: historySortDescriptor, range: range, handler: handler)
    }

    func loadHistoryItems(range: NSRange? = nil, startDate: NSDate, handler: [HistoryItem] -> ()) {
        let mapper = {HistoryItemMapper.historyItemWith($0)} // TODO loading shared users (when there are shared users) when accessing, crash: BAD_ACCESS, re-test after realm update
        self.load(mapper, predicate: NSPredicate(format: "addedDate >= %@", startDate), sortDescriptor: historySortDescriptor, range: range, handler: handler)
    }
    
    func saveHistoryItems(historyItems: RemoteHistoryItems, handler: Bool -> ()) {
        
        self.doInWriteTransaction({[weak self] realm in
            
            realm.delete(realm.objects(DBHistoryItem))
            
            let historyItemsWithRelations = HistoryItemMapper.historyItemsWithRemote(historyItems)
            
            self?.saveHistoryItemsHelper(realm, historyItemsWithRelations: historyItemsWithRelations)
            
            return true
            
            }, finishHandler: {success in
                handler(success)
            }
        )
    }

    func saveHistoryItems(historyItemsWithRelations: HistoryItemsWithRelations, handler: Bool -> ()) {
        
        self.doInWriteTransaction({[weak self] realm in
            
            realm.delete(realm.objects(DBHistoryItem))
            
            self?.saveHistoryItemsHelper(realm, historyItemsWithRelations: historyItemsWithRelations)
            
            return true
            
            }, finishHandler: {success in
                handler(success)
            }
        )
    }
    
    
    // common code, note that this is expected to be executed in a transaction
    private func saveHistoryItemsHelper(realm: Realm, historyItemsWithRelations: HistoryItemsWithRelations) {
        
        // save inventory items
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
            let dbHistoryItem = HistoryItemMapper.dbWithHistoryItem(historyItem)
            realm.add(dbHistoryItem, update: true)
        }
    }
    
    func saveHistoryItemsSyncResult(historyItems: RemoteHistoryItems, handler: Bool -> ()) {
        self.saveHistoryItems(historyItems, handler: handler)
    }
}
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
   
    let dbListItemProvider = RealmListItemProvider()
    let remoteInventoryProvider = RemoteInventoryProvider()
    
    func loadInventories(handler: [Inventory] -> ()) {
        let mapper = {InventoryMapper.inventoryWithDB($0)}
        self.load(mapper, handler: handler)
    }

//    func saveInventories(inventories: [DBInventory], handler: Bool -> ()) {
//        self.saveObjs(inventories, update: true, handler: handler)
//    }
    
//    func syncInventories(inventories incomingInventories: [DBInventory], handler: Bool -> ()) {
//        // update my inventories such my newest items and updates are not lost
//        
//        self.loadInventories {myInventories in
//            self.dbSyncProvider.loadSyncDate("inventory") {lastSyncDateMaybe in
//                
//                self.remoteInventoryProvider.syncInventories(myInventories) {
//                    
//                }
//                
//            }
//            
//            
//            
//            
////            var myInventoriesDictionary: [String: Inventory] = [:]
////            for inventory in myInventories {
////                myInventoriesDictionary[inventory.uuid] = inventory
////            }
////            
////            let inventoriesToSave = incomingInventories.filter {incomingInventory in
////                if let myInventory = myInventoriesDictionary[incomingInventory.uuid] {
////                    if myInventory.lastUpdate.timeIntervalSince1970 > incomingInventory.lastUpdate.timeIntervalSince1970 { // hm....
////                        return true
////                    } else {
////                        return false
////                    }
////
////                } else { // if the inventory is not in the local db yet, we want to save it
////                    return true
////                }
////            }
////            
//            
//            self.saveInventories(inventoriesToSave, handler: handler)
//        }
//    }

    
    func loadInventory(handler: [InventoryItem] -> ()) {
        let mapper = {InventoryItemMapper.inventoryItemWithDB($0)}
        self.load(mapper, handler: handler)
    }

    func saveInventory(inventory: Inventory, handler: Bool -> ()) {
        self.saveInventories([inventory], handler: handler)
    }
    
    func saveInventories(inventories: [Inventory], update: Bool = true, handler: Bool -> ()) {
        let dbLists = inventories.map{InventoryMapper.dbWithInventory($0)}
        self.saveObjs(dbLists, update: update, handler: handler)
    }
    
    func saveInventoryItems(items: [InventoryItem], handler: Bool -> ()) {
        let dbObjs = items.map{InventoryItemMapper.dbWithInventoryItem($0)}
        self.saveObjs(dbObjs, update: true, handler: handler)
    }
    
    func incrementInventoryItem(item: InventoryItem, delta: Int, handler: Bool -> ()) {
        let incrementedInventoryItem = item.copy(quantityDelta: item.quantityDelta + delta)
        
        saveInventoryItems([incrementedInventoryItem], handler: handler)
    }
    
    func removeInventoryItem(item: InventoryItem, handler: Bool -> ()) {
        let filter = DBInventoryItem.createFilter(item.product, item.inventory)
        self.remove(filter, handler: handler, objType: DBInventoryItem.self)
    }
    
    // hm...
    func loadAllInventoryItems(handler: [InventoryItem] -> ()) {
        let mapper = {InventoryItemMapper.inventoryItemWithDB($0)}
        self.load(mapper, handler: handler)
    }
    
    func saveInventoriesSyncResult(syncResult: RemoteInventoriesWithInventoryItemsSyncResult, handler: Bool -> ()) {
        
        self.doInWriteTransaction({realm in
            
            let inventories = realm.objects(DBInventory)
            let inventoryItems = realm.objects(DBInventoryItem)
            
            realm.delete(inventories)
            realm.delete(inventoryItems)
            
            // save inventories
            var dbInventoriesDict: [String: DBInventory] = [:] // cache saved inventories for fast access when saving inventory items, which need the inventory
            let remoteInventories = syncResult.inventories
            for remoteInventory in remoteInventories {
                let dbInventory = InventoryMapper.dbWithInventory(remoteInventory)
                dbInventoriesDict[remoteInventory.uuid] = dbInventory
                realm.add(dbInventory, update: true)
            }
            
            // save inventory items
            for inventoryItemsSyncResult in syncResult.inventoryItemsSyncResults {
                for inventoryItem in inventoryItemsSyncResult.inventoryItems {
                    if let dbInventory = dbInventoriesDict[inventoryItemsSyncResult.inventoryUuid] {
                        let dbInventoryItem = InventoryItemMapper.dbInventoryItemWithRemote(inventoryItem, inventory: dbInventory)
                        realm.add(dbInventoryItem, update: true)
                    } else {
                        print("Error: Invalid response: Inventory item sync response: No inventory found for inventory item uuid")
                        // TODO good unit test for this, also send to error monitoring
                        // This should not happen, but if it does we just don't save these inventory items. The rest continues normally.
                    }
                }
            }
            
            return true
            
        }, finishHandler: {success in
            handler(success)
        })
    }

    
    /**
    Adds inventory and corresponding history items, in a transaction
    */
    func add(inventoryItemsWithHistory: [InventoryItemWithHistoryEntry], handler: Bool -> ()) {
        
        self.doInWriteTransaction({[weak self] realm in
            
            if let weakSelf = self {
                synced(weakSelf) {
                    for var inventoryItemWithHistory in inventoryItemsWithHistory { // var because we overwrite with incremented item if already exists
                        
                        // increment if already exists (currently there doesn't seem to be any functionality to do this using Realm so we do it manually)
                        let mapper: DBInventoryItem -> InventoryItem = {InventoryItemMapper.inventoryItemWithDB($0)}
                        let inventoryItems: [InventoryItem] = self!.loadSync(realm, mapper: mapper, filter:
                            DBInventoryItem.createFilter(inventoryItemWithHistory.inventoryItem.product, inventoryItemWithHistory.inventoryItem.inventory)) // TODO if possible don't use implicity wrapped optional here?
                        if let inventoryItem = inventoryItems.first {
                            let currentQuantity = inventoryItem.quantity
                            let currentQuantityDelta = inventoryItem.quantityDelta
                            let inventoryItem = inventoryItemWithHistory.inventoryItem
                            let incrementedInventoryItem = inventoryItem.copy(quantity: inventoryItem.quantity + currentQuantity, quantityDelta: inventoryItem.quantityDelta + currentQuantityDelta)
                            inventoryItemWithHistory = inventoryItemWithHistory.copy(inventoryItem: incrementedInventoryItem)
                        }
                        
                        // save
                        let dbInventoryItem = InventoryItemMapper.dbWithInventoryItem(inventoryItemWithHistory.inventoryItem)
                        let dbHistoryItem = HistoryItemMapper.dbWith(inventoryItemWithHistory)
                        realm.add(dbInventoryItem, update: true)
                        realm.add(dbHistoryItem, update: true)
                    }
                }
                return true
                
            } else {
                print("Warning: no self reference in RealmInventoryProvider.add, doInWriteTransaction")
                return false
            }
            }, finishHandler: {success in
                handler(success)
            }
        )
    }
}
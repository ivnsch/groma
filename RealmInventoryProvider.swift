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

    func findInventoryItem(item: InventoryItem, handler: InventoryItem? -> ()) {
        let mapper = {InventoryItemMapper.inventoryItemWithDB($0)}
        self.loadFirst(mapper, filter: DBInventoryItem.createFilter(item.product, item.inventory), handler: handler)
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

    
    func loadInventory(sortBy: InventorySortBy, range: NSRange, handler: [InventoryItem] -> ()) {
        let mapper = {InventoryItemMapper.inventoryItemWithDB($0)}
//        let sortFieldStr: String = {
//            switch sortBy {
//            case .Alphabetic: return "product.name" // Realm doesn't support this yet, see https://github.com/realm/realm-cocoa/issues/1277 so for now we do sorting in provider
//            case .Count: return "quantity"
//            }
//        }()
        // range also not possible because sorting is not psosible. If we can't sort first then range is incorrect.
        self.load(mapper, /*range: range, sortDescriptor: NSSortDescriptor(key: sortFieldStr, ascending: false), */handler: handler)
    }
    
    func saveInventory(inventory: Inventory, update: Bool = true, handler: Bool -> ()) {
        self.saveInventories([inventory], update: update, handler: handler)
    }
    
    func saveInventories(inventories: [Inventory], update: Bool = true, handler: Bool -> ()) {
        let dbLists = inventories.map{InventoryMapper.dbWithInventory($0)}
        self.saveObjs(dbLists, update: update, handler: handler)
    }
    
    func saveInventoryItems(items: [InventoryItem], update: Bool =  true, handler: Bool -> ()) {
        let dbObjs = items.map{InventoryItemMapper.dbWithInventoryItem($0)}
        self.saveObjs(dbObjs, update: update, handler: handler)
    }

    
    func saveInventoryItem(item: InventoryItem, handler: Bool -> ()) {
        saveInventoryItems([item], handler: handler)
    }

    
    // TODO Asynchronous. dispatch_async + lock inside for some reason didn't work correctly (tap 10 times on increment, only shows 4 or so (after refresh view controller it's correct though), maybe use serial queue?
    // param onlyDelta: if we want to update only quantityDelta field (opposed to updating both quantity and quantityDelta)
    func incrementInventoryItem(item: InventoryItem, delta: Int, onlyDelta: Bool = false, handler: Bool -> ()) {

//        synced(self)  {
        
            // load
            let realm = try! Realm()
            var results = realm.objects(DBInventoryItem)
            results = results.filter(NSPredicate(format: DBInventoryItem.createFilter(item.product, item.inventory), argumentArray: []))
            let objs: [DBInventoryItem] = results.toArray(nil)
            let dbInventoryItems = objs.map{InventoryItemMapper.inventoryItemWithDB($0)}
            let inventoryItemMaybe = dbInventoryItems.first
            
            if let inventoryItem = inventoryItemMaybe {
                // increment
                let incrementedInventoryitem: InventoryItem =  {
                    if onlyDelta {
                        return inventoryItem.copy(quantityDelta: inventoryItem.quantityDelta + delta)
                    } else {
                        return inventoryItem.incrementQuantityCopy(delta)
                    }
                }()
                
                // convert to db object
                let dbIncrementedInventoryitem = InventoryItemMapper.dbWithInventoryItem(incrementedInventoryitem)
                
                
                // save
                realm.write {
                    for obj in objs {
                        obj.lastUpdate = NSDate()
                        realm.add(dbIncrementedInventoryitem, update: true)
                    }
                }
                
                handler(true)
                
                
            } else {
                print("Inventory item not found: \(item)")
                handler(false)
            }
//        }
    }
    
    
    func incrementInventoryItemOnlyDelta(item: InventoryItem, delta: Int, handler: Bool -> ()) {
        let incrementedInventoryItem = item.copy(quantityDelta: item.quantityDelta + delta)
        
        print("\n\nafter delta: \(delta), saving incrementedInventoryItem: \(incrementedInventoryItem)\n\n")
        
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
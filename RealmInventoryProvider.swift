//
//  RealmInventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs

class RealmInventoryProvider: RealmProvider {
   
    let dbListItemProvider = RealmListItemProvider()
    let remoteInventoryProvider = RemoteInventoryProvider()
    let dbProductProvider = RealmProductProvider()
    
    func loadInventories(handler: [Inventory] -> ()) {
        let mapper = {InventoryMapper.inventoryWithDB($0)}
        self.load(mapper, sortDescriptor: NSSortDescriptor(key: "order", ascending: true), handler: handler)
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

    
    func loadInventory(inventory: Inventory, sortBy: InventorySortBy, range: NSRange, handler: [InventoryItem] -> ()) {
        let mapper = {InventoryItemMapper.inventoryItemWithDB($0)} // TODO!!! Crash once accessing color() of category (in ProductCategoryMapper.categoryWithDB). Category is set but no color data, don't know why!
//        let sortFieldStr: String = {
//            switch sortBy {
//            case .Alphabetic: return "product.name" // Realm doesn't support this yet, see https://github.com/realm/realm-cocoa/issues/1277 so for now we do sorting in provider
//            case .Count: return "quantity"
//            }
//        }()
        // range also not possible because sorting is not psosible. If we can't sort first then range is incorrect.
        self.load(mapper, filter: DBInventoryItem.createFilterInventory(inventory.uuid), /*range: range, sortDescriptor: NSSortDescriptor(key: sortFieldStr, ascending: false), */handler: handler)
    }
    
    func saveInventory(inventory: Inventory, update: Bool = true, dirty: Bool, handler: Bool -> ()) {
        self.saveInventories([inventory], update: update, dirty: dirty, handler: handler)
    }
    
    func updateInventoriesOrder(orderUpdates: [OrderUpdate], dirty: Bool, _ handler: Bool -> Void) {
        doInWriteTransaction({realm in
            for orderUpdate in orderUpdates {
                realm.create(DBInventory.self, value: DBInventory.createOrderUpdateDict(orderUpdate, dirty: dirty), update: true)
            }
            return true
        }) {(successMaybe: Bool?) in
            handler(successMaybe ?? false)
        }
    }
    
    func removeInventory(uuid: String, update: Bool =  true, markForSync: Bool, handler: Bool -> ()) {
        background({[weak self] in
            do {
                let realm = try Realm()
                try realm.write {
                    self?.removeInventorySync(realm, inventoryUuid: uuid, markForSync: markForSync)
                }
                return true
            } catch let e {
                QL4("Realm error: \(e)")
                return false
            }
            }) {(result: Bool) in
                handler(result)
        }
    }
    
    func removeInventorySync(realm: Realm, inventoryUuid: String, markForSync: Bool) {
   
        removeInventoryDependenciesSync(realm, inventoryUuid: inventoryUuid, markForSync: markForSync)
        
        let inventoryResults = realm.objects(DBInventory).filter(DBInventory.createFilter(inventoryUuid))
        if markForSync {
            let toRemove = inventoryResults.map{DBRemoveInventory($0)}
            saveObjsSyncInt(realm, objs: toRemove, update: true)
        }
        realm.delete(inventoryResults)
    }
    
    func removeInventoryDependenciesSync(realm: Realm, inventoryUuid: String, markForSync: Bool) {
        DBProviders.listProvider.removeListsForInventory(realm, inventoryUuid: inventoryUuid, markForSync: markForSync)
        DBProviders.historyProvider.removeHistoryItemsForInventory(realm, inventoryUuid: inventoryUuid, markForSync: markForSync)
        DBProviders.inventoryItemProvider.removeInventoryItemsForInventorySync(realm, inventoryUuid: inventoryUuid, markForSync: markForSync)
    }
    
    func saveInventories(inventories: [Inventory], update: Bool = true, dirty: Bool, handler: Bool -> ()) {
        let dbInventories = inventories.map{InventoryMapper.dbWithInventory($0, dirty: dirty)}
        saveInventories(dbInventories, handler: handler)
    }
    
    func saveInventories(inventories: [DBInventory], update: Bool = true, handler: Bool -> ()) {
        self.saveObjs(inventories, update: update, handler: handler)
    }
    
    func overwrite(inventories: [Inventory], clearTombstones: Bool, dirty: Bool, handler: Bool -> Void) {
        let dbInventories = inventories.map{InventoryMapper.dbWithInventory($0, dirty: dirty)}
        let additionalActions: (Realm -> Void)? = clearTombstones ? {realm in realm.deleteAll(DBRemoveInventory)} : nil
        self.overwrite(dbInventories, resetLastUpdateToServer: true, idExtractor: {$0.uuid}, additionalActions: additionalActions, handler: handler)
    }
    
    // MARK: - Sync
    
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
                dbInventoriesDict[remoteInventory.inventory.uuid] = dbInventory
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
            handler(success ?? false)
        })
    }
    
    func clearInventoryTombstone(uuid: String, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveInventory.self, DBRemoveInventory.createFilter(uuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateLastSyncTimeStamp(inventory: RemoteInventory, handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateLastSyncTimeStampSync(realm, inventory: inventory)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateLastSyncTimeStampSync(realm: Realm, inventory: RemoteInventory) {
        realm.create(DBInventory.self, value: inventory.timestampUpdateDict, update: true)
    }
}
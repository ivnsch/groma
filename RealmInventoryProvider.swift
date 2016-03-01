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
    
    func loadInventories(handler: [Inventory] -> ()) {
        let mapper = {InventoryMapper.inventoryWithDB($0)}
        self.load(mapper, sortDescriptor: NSSortDescriptor(key: "order", ascending: true), handler: handler)
    }

    func findInventoryItem(item: InventoryItem, handler: InventoryItem? -> ()) {
        let mapper = {InventoryItemMapper.inventoryItemWithDB($0)}
        self.loadFirst(mapper, filter: DBInventoryItem.createFilter(item.product, item.inventory), handler: handler)
    }
    
    func findInventoryItem(productUuid: String, inventoryUuid: String, _ handler: InventoryItem? -> Void) {
        let mapper = {InventoryItemMapper.inventoryItemWithDB($0)}
        self.loadFirst(mapper, filter: DBInventoryItem.createFilter(productUuid, inventoryUuid), handler: handler)
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
        self.load(mapper, filter: DBInventoryItem.createFilter(inventory.uuid), /*range: range, sortDescriptor: NSSortDescriptor(key: sortFieldStr, ascending: false), */handler: handler)
    }
    
    func saveInventory(inventory: Inventory, update: Bool = true, handler: Bool -> ()) {
        self.saveInventories([inventory], update: update, handler: handler)
    }
    
    func removeInventory(uuid: String, update: Bool =  true, markForSync: Bool, handler: Bool -> ()) {
        background({[weak self] in
            do {
                let realm = try Realm()
                try realm.write {
                    RealmListItemProvider().removeListSync(realm, listUuid: uuid, markForSync: markForSync)
                    
                    RealmHistoryProvider().removeHistoryItemsForInventory(realm, inventoryUuid: uuid, markForSync: markForSync)
                    
                    let inventoryResults = realm.objects(DBInventory).filter(DBInventory.createFilter(uuid))
                    realm.delete(inventoryResults)
                    if markForSync {
                        let toRemove = inventoryResults.map{DBRemoveInventory($0)}
                        self?.saveObjsSyncInt(realm, objs: toRemove, update: true)
                    }
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
    
    func saveInventories(inventories: [Inventory], update: Bool = true, handler: Bool -> ()) {
        let dbInventories = inventories.map{InventoryMapper.dbWithInventory($0)}
        saveInventories(dbInventories, handler: handler)
    }
    
    func saveInventories(inventories: [DBInventory], update: Bool = true, handler: Bool -> ()) {
        self.saveObjs(inventories, update: update, handler: handler)
    }
    
    func overwrite(inventories: [Inventory], clearTombstones: Bool, handler: Bool -> Void) {
        let dbInventories = inventories.map{InventoryMapper.dbWithInventory($0)}
        let additionalActions: (Realm -> Void)? = clearTombstones ? {realm in realm.deleteAll(DBRemoveInventory)} : nil
        self.overwrite(dbInventories, resetLastUpdateToServer: true, additionalActions: additionalActions, handler: handler)
    }
    
    func saveInventoryItems(items: [InventoryItem], update: Bool =  true, handler: Bool -> ()) {
        let dbObjs = items.map{InventoryItemMapper.dbWithInventoryItem($0)}
        self.saveObjs(dbObjs, update: update, handler: handler)
    }

    func overwrite(items: [InventoryItem], inventoryUuid: String, clearTombstones: Bool, handler: Bool -> Void) {
        let dbObjs = items.map{InventoryItemMapper.dbWithInventoryItem($0)}
        
        let additionalActions: (Realm -> Void)? = clearTombstones ? {realm in realm.deleteForFilter(DBRemoveInventoryItem.self, DBRemoveInventoryItem.createFilterForInventory(inventoryUuid))} : nil

        self.overwrite(dbObjs, deleteFilter: DBInventoryItem.createFilter(inventoryUuid), resetLastUpdateToServer: true, additionalActions: additionalActions, handler: handler)
    }
    
    func saveInventoryItem(item: InventoryItem, handler: Bool -> ()) {
        saveInventoryItems([item], handler: handler)
    }

    
    // TODO Asynchronous. dispatch_async + lock inside for some reason didn't work correctly (tap 10 times on increment, only shows 4 or so (after refresh view controller it's correct though), maybe use serial queue?
    // param onlyDelta: if we want to update only quantityDelta field (opposed to updating both quantity and quantityDelta)
    func incrementInventoryItem(item: InventoryItem, delta: Int, onlyDelta: Bool = false, handler: Bool -> ()) {

        do {
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
                try realm.write {
                    for obj in objs {
                        obj.lastUpdate = NSDate()
                        realm.add(dbIncrementedInventoryitem, update: true)
                    }
                }
                
                handler(true)
                
                
            } else {
                print("Info: RealmInventoryProvider.incrementInventoryItem: Inventory item not found: \(item)")
                handler(false)
            }
            //        }
            
        } catch let e {
            QL4("Realm error: \(e)")
            handler(false)
        }
    }
    
    
    func incrementInventoryItemOnlyDelta(item: InventoryItem, delta: Int, handler: Bool -> ()) {
        let incrementedInventoryItem = item.copy(quantityDelta: item.quantityDelta + delta)
        
        print("\n\nafter delta: \(delta), saving incrementedInventoryItem: \(incrementedInventoryItem)\n\n")
        
        saveInventoryItems([incrementedInventoryItem], handler: handler)
    }
    
    func removeInventoryItem(inventoryItem: InventoryItem, markForSync: Bool, handler: Bool -> ()) {
        let filter = DBInventoryItem.createFilter(inventoryItem)
        
        let additionalActions: (Realm -> Void)? = markForSync ? {realm in
            let toRemoveInventoryItem = DBRemoveInventoryItem(inventoryItem)
            realm.add(toRemoveInventoryItem, update: true)
        } : nil
        
        self.remove(filter, handler: handler, objType: DBInventoryItem.self, additionalActions: additionalActions)
    }
    
    func removeInventoryItem(productUuid: String, inventoryUuid: String, markForSync: Bool, handler: Bool -> ()) {
        // Needs custom handling because DBRemoveInventoryItem needs the lastUpdate server timestamp and for this we have to retrieve the item from db
        self.doInWriteTransaction({realm in
            if let itemToRemove = realm.objects(DBInventoryItem).filter(DBInventoryItem.createFilter(productUuid, inventoryUuid)).first {
                realm.delete(itemToRemove)
                if markForSync {
                    let toRemoveInventoryItem = DBRemoveInventoryItem(productUuid: productUuid, inventoryUuid: inventoryUuid, lastServerUpdate: itemToRemove.lastServerUpdate)
                    realm.add(toRemoveInventoryItem, update: true)
                }
            }
            return true
            
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    // hm...
    func loadAllInventoryItems(handler: [InventoryItem] -> ()) {
        let mapper = {InventoryItemMapper.inventoryItemWithDB($0)}
        self.load(mapper, handler: handler)
    }

    func countInventoryItems(inventory: Inventory, handler: Int? -> Void) {
        withRealm({realm in
            realm.objects(DBInventoryItem).filter(DBInventoryItem.createFilter(inventory.uuid)).count
            }) { (countMaybe: Int?) -> Void in
                if let count = countMaybe {
                    handler(count)
                } else {
                    QL4("No count")
                    handler(nil)
            }
        }
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
            handler(success ?? false)
        })
    }

    
    /**
    Adds inventory and corresponding history items, in a transaction
    */
    func add(inventoryItemsWithHistory: [InventoryItemWithHistoryEntry], handler: Bool -> ()) {
        
        self.doInWriteTransaction({[weak self] realm in
            
            if let weakSelf = self {
                synced(weakSelf) {
                    for inventoryItemWithHistory in inventoryItemsWithHistory { // var because we overwrite with incremented item if already exists
                        
                        // increment if already exists (currently there doesn't seem to be any functionality to do this using Realm so we do it manually)
                        let mapper: DBInventoryItem -> InventoryItem = {InventoryItemMapper.inventoryItemWithDB($0)}
                        let inventoryItems: [InventoryItem] = self!.loadSync(realm, mapper: mapper, filter:
                            DBInventoryItem.createFilter(inventoryItemWithHistory.inventoryItem.product, inventoryItemWithHistory.inventoryItem.inventory)) // TODO if possible don't use implicity wrapped optional here?
                        
                        let incrementedOrSameInventoryItem: InventoryItem = {
                            if let inventoryItem = inventoryItems.first {
                                let currentQuantity = inventoryItem.quantity
                                let currentQuantityDelta = inventoryItem.quantityDelta
                                let inventoryItem = inventoryItemWithHistory.inventoryItem
                                return inventoryItem.copy(quantity: inventoryItem.quantity + currentQuantity, quantityDelta: inventoryItem.quantityDelta + currentQuantityDelta)
                                //                            inventoryItemWithHistory = inventoryItemWithHistory.copy(inventoryItem: incrementedInventoryItem)
                                
                            } else { // if item doesn't exist there's nothing to increment
                                return inventoryItemWithHistory.inventoryItem
                            }
                        }()
                        
                        // save
                        let dbInventoryItem = InventoryItemMapper.dbWithInventoryItem(incrementedOrSameInventoryItem)
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
                handler(success ?? false)
            }
        )
    }
    
    func clearInventoryTombstone(uuid: String, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveInventory.self, DBRemoveInventory.createFilter(uuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func clearInventoryItemTombstone(productUuid: String, inventoryUuid: String, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveInventoryItem.self, DBRemoveInventoryItem.createFilter(productUuid, inventoryUuid: inventoryUuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateLastSyncTimeStamp(items: RemoteInventoryItemsWithHistoryAndDependencies, handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            for listItem in items.inventoryItems {
                realm.create(DBInventoryItem.self, value: listItem.timestampUpdateDict, update: true)
            }
            for product in items.products {
                realm.create(DBProduct.self, value: product.timestampUpdateDict, update: true)
            }
            for productCategory in items.productsCategories {
                realm.create(DBProductCategory.self, value: productCategory.timestampUpdateDict, update: true)
            }
            for inventory in items.inventories {
                self?.updateLastSyncTimeStampSync(realm, inventory: inventory)
            }
            for historyItem in items.historyItems {
                realm.create(DBHistoryItem.self, value: historyItem.timestampUpdateDict, update: true)
            }
            // TODO shared users? - probably not as we can't edit shared users so there's nothing to sync
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
    
    private func updateLastSyncTimeStampSync(realm: Realm, inventory: RemoteInventory) {
        realm.create(DBInventory.self, value: inventory.timestampUpdateDict, update: true)
    }
}
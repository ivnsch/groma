//
//  RealmInventoryItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 14/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs

class RealmInventoryItemProvider: RealmProvider {
    
    func findInventoryItem(item: InventoryItem, handler: InventoryItem? -> ()) {
        let mapper = {InventoryItemMapper.inventoryItemWithDB($0)}
        self.loadFirst(mapper, filter: DBInventoryItem.createFilter(item.product, item.inventory), handler: handler)
    }
    
    func findInventoryItem(uuid: String, _ handler: InventoryItem? -> Void) {
        let mapper = {InventoryItemMapper.inventoryItemWithDB($0)}
        self.loadFirst(mapper, filter: DBInventoryItem.createFilterUuid(uuid), handler: handler)
    }
    
    
    func saveInventoryItems(items: [InventoryItem], update: Bool =  true, dirty: Bool, handler: Bool -> ()) {
        let dbObjs = items.map{InventoryItemMapper.dbWithInventoryItem($0, dirty: dirty)}
        self.saveObjs(dbObjs, update: update, handler: handler)
    }
    
    func overwrite(items: [InventoryItem], inventoryUuid: String, clearTombstones: Bool, dirty: Bool, handler: Bool -> Void) {
        let dbObjs = items.map{InventoryItemMapper.dbWithInventoryItem($0, dirty: dirty)}
        
        let additionalActions: (Realm -> Void)? = clearTombstones ? {realm in realm.deleteForFilter(DBRemoveInventoryItem.self, DBRemoveInventoryItem.createFilterForInventory(inventoryUuid))} : nil
        
        self.overwrite(dbObjs, deleteFilter: DBInventoryItem.createFilterInventory(inventoryUuid), resetLastUpdateToServer: true, idExtractor: {$0.uuid}, additionalActions: additionalActions, handler: handler)
    }
    
    func saveInventoryItem(item: InventoryItem, dirty: Bool, handler: Bool -> ()) {
        saveInventoryItems([item], dirty: dirty, handler: handler)
    }
    
    
    func saveInventoryAndHistoryItem(inventoryItems: [InventoryItem], historyItems: [HistoryItem], dirty: Bool, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            
            let dbInventoryItem = inventoryItems.map{InventoryItemMapper.dbWithInventoryItem($0, dirty: dirty)}
            let dbHistorytem = historyItems.map{HistoryItemMapper.dbWithHistoryItem($0, dirty: dirty)}
            realm.add(dbInventoryItem, update: true) // update true just in case
            realm.add(dbHistorytem, update: true) // update true just in case
            return true
            
            }) {(successMaybe: Bool?) in
            handler(successMaybe ?? false)
        }
    }
    
    func incrementInventoryItem(itemUuid: String, delta: Int, onlyDelta: Bool = false, dirty: Bool, handler: Bool -> ()) {
        
        doInWriteTransaction({realm in
            
            var results = realm.objects(DBInventoryItem)
            results = results.filter(NSPredicate(format: DBInventoryItem.createFilterUuid(itemUuid), argumentArray: []))
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
                let dbIncrementedInventoryitem = InventoryItemMapper.dbWithInventoryItem(incrementedInventoryitem, dirty: dirty)
                
                // save
                realm.add(dbIncrementedInventoryitem, update: true)
                return true
                
            } else {
                QL3("Inventory item not found: \(itemUuid)")
                return false
            }
            
        }) {(successMaybe: Bool?) in
            handler(successMaybe ?? false)
        }
    }
    
    // TODO Asynchronous. dispatch_async + lock inside for some reason didn't work correctly (tap 10 times on increment, only shows 4 or so (after refresh view controller it's correct though), maybe use serial queue?
    // param onlyDelta: if we want to update only quantityDelta field (opposed to updating both quantity and quantityDelta)
    func incrementInventoryItem(item: InventoryItem, delta: Int, onlyDelta: Bool = false, dirty: Bool, handler: Bool -> ()) {
        incrementInventoryItem(item.uuid, delta: delta, onlyDelta: onlyDelta, dirty: dirty, handler: handler)
    }
    
    private func incrementInventoryItemSync(realm: Realm, dbInventoryItem: DBInventoryItem, delta: Int, onlyDelta: Bool = false, dirty: Bool) {
        
        // convert to model obj because the increment functions are in the model obj (we could also add them to the db obj)
        let inventoryItem = InventoryItemMapper.inventoryItemWithDB(dbInventoryItem)
        
        // increment
        let incrementedInventoryitem: InventoryItem = {
            if onlyDelta {
                return inventoryItem.copy(quantityDelta: inventoryItem.quantityDelta + delta)
            } else {
                return inventoryItem.incrementQuantityCopy(delta)
            }
        }()
        
        // convert to db object
        let dbIncrementedInventoryitem = InventoryItemMapper.dbWithInventoryItem(incrementedInventoryitem, dirty: dirty)
        
        // save
        realm.add(dbIncrementedInventoryitem, update: true)
    }
    
    
    func addOrIncrementInventoryItemWithInput(itemInputs: [ProductWithQuantityInput], inventory: Inventory, dirty: Bool, handler: [InventoryItemWithHistoryEntry]? -> Void) {
        
        self.doInWriteTransaction({[weak self] realm in
            
            if let weakSelf = self {
                // Note: map in this case has side effects - it adds the inventory/history to the database
                let addedInventoryItemsWithHistoryEntries = itemInputs.map {itemInput in
                    weakSelf.addOrIncrementInventoryItemWithProduct(realm, product: itemInput.product, inventory: inventory, quantity: itemInput.quantity, dirty: dirty)
                }
                return addedInventoryItemsWithHistoryEntries
            }
            return nil
            
            }, finishHandler: {(addedInventoryItemsWithHistoryEntriesMaybe: [InventoryItemWithHistoryEntry]?) in
                handler(addedInventoryItemsWithHistoryEntriesMaybe)
        })
        
    }
    
    // Helper function for common code
    // This is only called when using quick add, not +/-.
    private func addOrIncrementInventoryItemWithProduct(realm: Realm, product: StoreProduct, inventory: Inventory, quantity: Int, dirty: Bool) -> InventoryItemWithHistoryEntry {
        let inventoryItemWithHistoryEntry = InventoryItemWithHistoryEntry(
            inventoryItem: InventoryItem(uuid: NSUUID().UUIDString, quantity: quantity, quantityDelta: quantity, product: product.product, inventory: inventory),
            historyItemUuid: NSUUID().UUIDString,
            paidPrice: product.price,
            addedDate: NSDate().toMillis(),
            user: ProviderFactory().userProvider.mySharedUser ?? SharedUser(email: "")
        )
        
        // add/increment item and add history entry
        addSync(realm, inventoryItemsWithHistory: [inventoryItemWithHistoryEntry], dirty: dirty)
        
        return inventoryItemWithHistoryEntry
    }
    
    // NOTE: Adds also history item.
    // Outdated implementation, needs now store product
//    func addOrIncrementInventoryItemWithInput(itemInput: InventoryItemInput, inventory: Inventory, delta: Int, onlyDelta: Bool = false, handler: InventoryItemWithHistoryEntry? -> ()) {
//        
//        self.doInWriteTransaction({[weak self] realm in
//            
//            if let weakSelf = self {
//                // upsert product
//                let updatedDbProduct = DBProviders.productProvider.upsertProductSync(realm, prototype: itemInput.productPrototype)
//                
//                // create new inventory item + history entry
//                let product = ProductMapper.productWithDB(updatedDbProduct)
//                return weakSelf.addOrIncrementInventoryItemWithProduct(realm, product: product, inventory: inventory, quantity: itemInput.quantity)
//            }
//            return nil
//            
//            }, finishHandler: {(addedInventoryItemWithHistoryEntryMaybe: InventoryItemWithHistoryEntry?) in
//                handler(addedInventoryItemWithHistoryEntryMaybe)
//        })
//    }
    
    func incrementInventoryItemOnlyDelta(item: InventoryItem, delta: Int, dirty: Bool, handler: Bool -> ()) {
        let incrementedInventoryItem = item.copy(quantityDelta: item.quantityDelta + delta)
        
        print("\n\nafter delta: \(delta), saving incrementedInventoryItem: \(incrementedInventoryItem)\n\n")
        
        saveInventoryItems([incrementedInventoryItem], dirty: dirty, handler: handler)
    }
    
    func removeInventoryItem(inventoryItem: InventoryItem, markForSync: Bool, handler: Bool -> Void) {
        removeInventoryItem(inventoryItem.uuid, inventoryUuid: inventoryItem.inventory.uuid, markForSync: markForSync, handler: handler)
    }
    
    func removeInventoryItem(uuid: String, inventoryUuid: String, markForSync: Bool, handler: Bool -> Void) {
        // Needs custom handling because DBRemoveInventoryItem needs the lastUpdate server timestamp and for this we have to retrieve the item from db
        self.doInWriteTransaction({realm in
            if let itemToRemove = realm.objects(DBInventoryItem).filter(DBInventoryItem.createFilterUuid(uuid)).first {
                if markForSync {
                    let toRemoveInventoryItem = DBRemoveInventoryItem(uuid: uuid, inventoryUuid: inventoryUuid, lastServerUpdate: itemToRemove.lastServerUpdate)
                    realm.add(toRemoveInventoryItem, update: true)
                }
                realm.delete(itemToRemove)
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
            realm.objects(DBInventoryItem).filter(DBInventoryItem.createFilterInventory(inventory.uuid)).count
            }) { (countMaybe: Int?) -> Void in
                if let count = countMaybe {
                    handler(count)
                } else {
                    QL4("No count")
                    handler(nil)
                }
        }
    }
    
    
    /**
     Adds inventory and corresponding history items, in a transaction
     */
    func add(inventoryItemsWithHistory: [InventoryItemWithHistoryEntry], dirty: Bool, handler: Bool -> ()) {
        
        self.doInWriteTransaction({[weak self] realm in
            
            if let weakSelf = self {
                synced(weakSelf) {
                    self?.addSync(realm, inventoryItemsWithHistory: inventoryItemsWithHistory, dirty: dirty)
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
    
    func updateInventoryItemWithIncrementResult(incrementResult: RemoteIncrementResult, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            if let storedItem = (realm.objects(DBInventoryItem).filter(DBInventoryItem.createFilterUuid(incrementResult.uuid)).first) {
                
                // Notes & todo see equivalent method for list items
                if (storedItem.lastServerUpdate <= incrementResult.lastUpdate) {
                    
                    var updateDict: [String: AnyObject] = DBSyncable.timestampUpdateDict(incrementResult.uuid, lastServerUpdate: incrementResult.lastUpdate)
                    updateDict[DBInventoryItem.quantityFieldName] = incrementResult.updatedQuantity
                    realm.create(DBInventoryItem.self, value: updateDict, update: true)
                    QL1("Updateded inventory item with increment result dict: \(updateDict)")
                    
                } else {
                    QL3("Warning: got result with smaller timestamp: \(incrementResult), ignoring")
                }
            } else {
                QL3("Didn't find item for: \(incrementResult)")
            }
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    // MARK: - Sync

    private func addSync(realm: Realm, inventoryItemsWithHistory: [InventoryItemWithHistoryEntry], dirty: Bool) {
        for inventoryItemWithHistory in inventoryItemsWithHistory { // var because we overwrite with incremented item if already exists
            
            // increment if already exists (currently there doesn't seem to be any functionality to do this using Realm so we do it manually)
            let mapper: DBInventoryItem -> InventoryItem = {InventoryItemMapper.inventoryItemWithDB($0)}
            let existingInventoryItems: [InventoryItem] = loadSync(realm, mapper: mapper, filter:
                DBInventoryItem.createFilter(inventoryItemWithHistory.inventoryItem.product, inventoryItemWithHistory.inventoryItem.inventory)) // TODO if possible don't use implicity wrapped optional here?
            
            let incrementedOrSameInventoryItem: InventoryItem = {
                if let existingInventoryItem = existingInventoryItems.first {
                    let existingQuantity = existingInventoryItem.quantity
                    let existingQuantityDelta = existingInventoryItem.quantityDelta
                    let inventoryItem = inventoryItemWithHistory.inventoryItem
                    return existingInventoryItem.copy(quantity: inventoryItem.quantity + existingQuantity, quantityDelta: inventoryItem.quantityDelta + existingQuantityDelta)
                    //                            inventoryItemWithHistory = inventoryItemWithHistory.copy(inventoryItem: incrementedInventoryItem)
                    
                } else { // if item doesn't exist there's nothing to increment
                    return inventoryItemWithHistory.inventoryItem
                }
            }()
            
            // save
            let dbInventoryItem = InventoryItemMapper.dbWithInventoryItem(incrementedOrSameInventoryItem, dirty: dirty)
            let dbHistoryItem = HistoryItemMapper.dbWith(inventoryItemWithHistory, dirty: dirty)
            realm.add(dbInventoryItem, update: true)
            realm.add(dbHistoryItem, update: true)
        }
    }
    
    func clearInventoryItemTombstone(uuid: String, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveInventoryItem.self, DBRemoveInventoryItem.createFilterUuid(uuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateInventoryItemLastUpdate(updateDict: [String: AnyObject], handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateInventoryItemLastUpdate(realm, updateDict: updateDict)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateInventoryItemLastUpdate(realm: Realm, updateDict: [String: AnyObject]) {
        realm.create(DBInventoryItem.self, value: updateDict, update: true)
    }

    func updateInventoryItemLastUpdate(item: RemoteInventoryItemWithProduct, handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateInventoryItemLastUpdate(realm, updateDict: item.inventoryItem.timestampUpdateDict)
            realm.create(DBProduct.self, value: item.product.timestampUpdateDict, update: true)
            realm.create(DBProductCategory.self, value: item.productCategory.timestampUpdateDict, update: true)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateLastSyncTimeStamp(items: RemoteInventoryItemsWithHistoryAndDependencies, handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            for listItem in items.inventoryItems {
                self?.updateInventoryItemLastUpdate(realm, updateDict: listItem.timestampUpdateDict)
            }
            for product in items.products {
                realm.create(DBProduct.self, value: product.timestampUpdateDict, update: true)
            }
            for productCategory in items.productsCategories {
                realm.create(DBProductCategory.self, value: productCategory.timestampUpdateDict, update: true)
            }
            for inventory in items.inventories {
                DBProviders.inventoryProvider.updateLastSyncTimeStampSync(realm, inventory: inventory)
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
}

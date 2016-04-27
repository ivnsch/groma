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
    
    func incrementInventoryItem(itemUuid: String, delta: Int, onlyDelta: Bool = false, dirty: Bool, handler: Int? -> ()) {
        
        doInWriteTransaction({realm in
            
            syncedRet(self) {

                let results = realm.objects(DBInventoryItem).filter(DBInventoryItem.createFilterUuid(itemUuid)).toArray()
                let dbInventoryItems = results.map{InventoryItemMapper.inventoryItemWithDB($0)}
                
                if let inventoryItem = dbInventoryItems.first {
                    let incrementedInventoryitem: InventoryItem =  {
                        if onlyDelta {
                            return inventoryItem.copy(quantityDelta: inventoryItem.quantityDelta + delta)
                        } else {
                            return inventoryItem.incrementQuantityCopy(delta)
                        }
                    }()
                    
                    let dbIncrementedInventoryitem = InventoryItemMapper.dbWithInventoryItem(incrementedInventoryitem, dirty: dirty)
                    
                    realm.add(dbIncrementedInventoryitem, update: true)
                    
                    return dbIncrementedInventoryitem.quantity
                    
                } else {
                    QL3("Inventory item not found: \(itemUuid)")
                    return nil
                }
            }
            
        }) {(updatedQuantityMaybe: Int?) in
            QL2("Calling handler")
            handler(updatedQuantityMaybe)
        }
    }
    
    // TODO Asynchronous. dispatch_async + lock inside for some reason didn't work correctly (tap 10 times on increment, only shows 4 or so (after refresh view controller it's correct though), maybe use serial queue?
    // param onlyDelta: if we want to update only quantityDelta field (opposed to updating both quantity and quantityDelta)
    func incrementInventoryItem(item: InventoryItem, delta: Int, onlyDelta: Bool = false, dirty: Bool, handler: Int? -> ()) {
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
    
    
    
    func addOrIncrementInventoryItemWithInput(itemInputs: [ProductWithQuantityInput], inventory: Inventory, dirty: Bool, handler: [InventoryItemWithHistoryItem]? -> Void) {
        
        self.doInWriteTransaction({[weak self] realm in
            return self?.addSync(realm, items: itemInputs, inventory: inventory, dirty: dirty)
            }, finishHandler: {(addedInventoryItemsWithHistoryEntriesMaybe: [InventoryItemWithHistoryItem]?) in
                handler(addedInventoryItemsWithHistoryEntriesMaybe)
        })
        
    }
    
    // TODO used? remove?
    func addOrIncrementInventoryItemsWithProductSync(realm: Realm, itemInputs: [ProductWithQuantityInput], inventory: Inventory, dirty: Bool) -> [InventoryItemWithHistoryItem] {
        return addSync(realm, items: itemInputs, inventory: inventory, dirty: dirty)
    }
    
    // Helper function for common code
    // This is only called when using quick add, not +/-.
    private func addOrIncrementInventoryItemWithProductSync(realm: Realm, product: StoreProduct, inventory: Inventory, quantity: Int, dirty: Bool) -> InventoryItemWithHistoryItem? {

        // add/increment item and add history entry
        let items = addSync(realm, items: [ProductWithQuantityInput(product: product, quantity: quantity)], inventory: inventory, dirty: dirty)
        
        if items.count != 1 {
            QL4("Not expected result items count: \(items.count), items: \(items)")
        }
        
        return items.first
    }
    
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
        self.doInWriteTransaction({[weak self] realm in
            if let itemToRemove = realm.objects(DBInventoryItem).filter(DBInventoryItem.createFilterUuid(uuid)).first {
                self?.removeInventoryItemSync(realm, dbInventoryItem: itemToRemove, markForSync: markForSync)
            }
            return true
            
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func removeInventoryItemSync(realm: Realm, dbInventoryItem: DBInventoryItem, markForSync: Bool) {
        if markForSync {
            let toRemoveInventoryItem = DBRemoveInventoryItem(uuid: dbInventoryItem.uuid, inventoryUuid: dbInventoryItem.inventory.uuid, lastServerUpdate: dbInventoryItem.lastServerUpdate)
            realm.add(toRemoveInventoryItem, update: true)
        }
        realm.delete(dbInventoryItem)
    }
    
    // Expected to be executed in do/catch and write block
    func removeInventoryItemsForInventorySync(realm: Realm, inventoryUuid: String, markForSync: Bool) -> Bool {
        let dbInventoryItems = realm.objects(DBInventoryItem).filter(DBInventoryItem.createFilterInventory(inventoryUuid))
        for dbInventoryItem in dbInventoryItems {
            removeInventoryItemSync(realm, dbInventoryItem: dbInventoryItem, markForSync: markForSync)
        }
        return true
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
    
    func updateInventoryItemWithIncrementResult(incrementResult: RemoteIncrementResult, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            if let storedItem = (realm.objects(DBInventoryItem).filter(DBInventoryItem.createFilterUuid(incrementResult.uuid)).first) {
                
                // store the timestamp only if it matches with the current quantity. E.g. if user increments very quicky 1,2,3,4,5,6
                // we may receive the response from server for 1 when the database is already at 4 - so we don't want to store 1's timestamp for 4. When the user stops at 6 only the timestamp with the response with 6 quantity will be stored.
                if storedItem.quantity == incrementResult.updatedQuantity {
                    // Notes & todo see equivalent method for list items
                    if (storedItem.lastServerUpdate <= incrementResult.lastUpdate) {
                        
                        let updateDict: [String: AnyObject] = DBSyncable.timestampUpdateDict(incrementResult.uuid, lastServerUpdate: incrementResult.lastUpdate)
                        realm.create(DBInventoryItem.self, value: updateDict, update: true)
                        QL1("Updateded inventory item with increment result dict: \(updateDict)")
                        
                    } else {
                        QL3("Warning: got result with smaller timestamp: \(incrementResult), ignoring")
                    }
                } else {
                    QL1("Received increment result with outdated quantity: \(incrementResult.updatedQuantity)")
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

    private func addSync(realm: Realm, items: [ProductWithQuantityInput], inventory: Inventory, dirty: Bool) -> [(inventoryItem: InventoryItem, historyItem: HistoryItem)] {
        
        let addedDate = NSDate().toMillis()
        
        let sharedUser = ProviderFactory().userProvider.mySharedUser ?? SharedUser(email: "")
        
        var adddedOrUpdatedItems: [(inventoryItem: InventoryItem, historyItem: HistoryItem)] = []
        
        for item in items {
            
            // increment if already exists (currently there doesn't seem to be any functionality to do this using Realm so we do it manually)
            let mapper: DBInventoryItem -> InventoryItem = {InventoryItemMapper.inventoryItemWithDB($0)}
            let existingInventoryItems: [InventoryItem] = loadSync(realm, mapper: mapper, filter:
                DBInventoryItem.createFilter(item.product.product, inventory))
            
            let addedOrIncrementedInventoryItem: InventoryItem = {
                if let existingInventoryItem = existingInventoryItems.first {
                    let existingQuantity = existingInventoryItem.quantity
                    let existingQuantityDelta = existingInventoryItem.quantityDelta

                    return existingInventoryItem.copy(quantity: item.quantity + existingQuantity, quantityDelta: item.quantity + existingQuantityDelta)
                    
                } else { // if item doesn't exist there's nothing to increment
                    return InventoryItem(uuid: NSUUID().UUIDString, quantity: item.quantity, quantityDelta: item.quantity, product: item.product.product, inventory: inventory)
                }
            }()
            
            // save
            let dbInventoryItem = InventoryItemMapper.dbWithInventoryItem(addedOrIncrementedInventoryItem, dirty: dirty)
            
            let historyItem = HistoryItem(uuid: NSUUID().UUIDString, inventory: inventory, product: item.product.product, addedDate: addedDate, quantity: item.quantity, user: sharedUser, paidPrice: item.product.price)
            
            let dbHistoryItem = HistoryItemMapper.dbWithHistoryItem(historyItem, dirty: dirty)
            realm.add(dbInventoryItem, update: true)
            realm.add(dbHistoryItem, update: true)
            
            adddedOrUpdatedItems.append((inventoryItem: addedOrIncrementedInventoryItem, historyItem: historyItem))
        }
        
        return adddedOrUpdatedItems
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
                DBProviders.inventoryProvider.updateLastSyncTimeStampSync(realm, inventory: inventory.inventory)
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

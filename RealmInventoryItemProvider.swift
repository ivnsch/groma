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
    
    func findInventoryItem(_ item: InventoryItem, handler: @escaping (InventoryItem?) -> ()) {
        let mapper = {InventoryItemMapper.inventoryItemWithDB($0)}
        self.loadFirst(mapper, filter: DBInventoryItem.createFilter(item.product, item.inventory), handler: handler)
    }
    
    func findInventoryItem(_ uuid: String, _ handler: @escaping (InventoryItem?) -> Void) {
        let mapper = {InventoryItemMapper.inventoryItemWithDB($0)}
        self.loadFirst(mapper, filter: DBInventoryItem.createFilterUuid(uuid), handler: handler)
    }
    
    
    func saveInventoryItems(_ items: [InventoryItem], update: Bool =  true, dirty: Bool, handler: @escaping (Bool) -> ()) {
        let dbObjs = items.map{InventoryItemMapper.dbWithInventoryItem($0, dirty: dirty)}
        self.saveObjs(dbObjs, update: update, handler: handler)
    }
    
    func overwrite(_ items: [InventoryItem], inventoryUuid: String, clearTombstones: Bool, dirty: Bool, handler: @escaping (Bool) -> Void) {
        let dbObjs = items.map{InventoryItemMapper.dbWithInventoryItem($0, dirty: dirty)}
        
        let additionalActions: ((Realm) -> Void)? = clearTombstones ? {realm in realm.deleteForFilter(DBRemoveInventoryItem.self, DBRemoveInventoryItem.createFilterForInventory(inventoryUuid))} : nil
        
        self.overwrite(dbObjs, deleteFilter: DBInventoryItem.createFilterInventory(inventoryUuid), resetLastUpdateToServer: true, idExtractor: {$0.uuid}, additionalActions: additionalActions, handler: handler)
    }
    
    func saveInventoryItem(_ item: InventoryItem, dirty: Bool, handler: @escaping (Bool) -> ()) {
        saveInventoryItems([item], dirty: dirty, handler: handler)
    }
    
    
    func saveInventoryAndHistoryItem(_ inventoryItems: [InventoryItem], historyItems: [HistoryItem], dirty: Bool, handler: @escaping (Bool) -> Void) {
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
    
    func incrementInventoryItem(_ itemUuid: String, delta: Int, onlyDelta: Bool = false, dirty: Bool, handler: @escaping (DBResult<Int>) -> Void) {
        
        doInWriteTransaction({realm in
            
            syncedRet(self) {

                let results = realm.objects(DBInventoryItem.self).filter(DBInventoryItem.createFilterUuid(itemUuid)).toArray()
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
                    
                    return DBResult(status: .notFound, sucessResult: dbIncrementedInventoryitem.quantity)
                    
                } else {
                    QL3("Inventory item not found: \(itemUuid)")
                    return DBResult(status: .notFound)
                }
            }
            
        }) {(result: DBResult<Int>?) in
            QL2("Calling handler")
            handler(result ?? DBResult(status: .unknown))
        }
    }
    
    // TODO Asynchronous. dispatch_async + lock inside for some reason didn't work correctly (tap 10 times on increment, only shows 4 or so (after refresh view controller it's correct though), maybe use serial queue?
    // param onlyDelta: if we want to update only quantityDelta field (opposed to updating both quantity and quantityDelta)
    func incrementInventoryItem(_ item: InventoryItem, delta: Int, onlyDelta: Bool = false, dirty: Bool, handler: @escaping (DBResult<Int>) -> Void) {
        incrementInventoryItem(item.uuid, delta: delta, onlyDelta: onlyDelta, dirty: dirty, handler: handler)
    }
    
    fileprivate func incrementInventoryItemSync(_ realm: Realm, dbInventoryItem: DBInventoryItem, delta: Int, onlyDelta: Bool = false, dirty: Bool) {
        
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
    
    
    
    func addOrIncrementInventoryItemWithInput(_ itemInputs: [ProductWithQuantityInput], inventory: DBInventory, dirty: Bool, handler: @escaping ([InventoryItemWithHistoryItem]?) -> Void) {
        
        self.doInWriteTransaction({[weak self] realm in
            return self?.addSync(realm, items: itemInputs, inventory: inventory, dirty: dirty)
            }, finishHandler: {(addedInventoryItemsWithHistoryEntriesMaybe: [InventoryItemWithHistoryItem]?) in
                handler(addedInventoryItemsWithHistoryEntriesMaybe)
        })
        
    }
    
    // TODO used? remove?
    func addOrIncrementInventoryItemsWithProductSync(_ realm: Realm, itemInputs: [ProductWithQuantityInput], inventory: DBInventory, dirty: Bool) -> [InventoryItemWithHistoryItem] {
        return addSync(realm, items: itemInputs, inventory: inventory, dirty: dirty)
    }
    
    // Helper function for common code
    // This is only called when using quick add, not +/-.
    fileprivate func addOrIncrementInventoryItemWithProductSync(_ realm: Realm, product: StoreProduct, inventory: DBInventory, quantity: Int, dirty: Bool) -> InventoryItemWithHistoryItem? {

        // add/increment item and add history entry
        let items = addSync(realm, items: [ProductWithQuantityInput(product: product, quantity: quantity)], inventory: inventory, dirty: dirty)
        
        if items.count != 1 {
            QL4("Not expected result items count: \(items.count), items: \(items)")
        }
        
        return items.first
    }
    
    func incrementInventoryItemOnlyDelta(_ item: InventoryItem, delta: Int, dirty: Bool, handler: @escaping (Bool) -> ()) {
        let incrementedInventoryItem = item.copy(quantityDelta: item.quantityDelta + delta)
        
        print("\n\nafter delta: \(delta), saving incrementedInventoryItem: \(incrementedInventoryItem)\n\n")
        
        saveInventoryItems([incrementedInventoryItem], dirty: dirty, handler: handler)
    }
    
    func removeInventoryItem(_ inventoryItem: InventoryItem, markForSync: Bool, handler: @escaping (Bool) -> Void) {
        removeInventoryItem(inventoryItem.uuid, inventoryUuid: inventoryItem.inventory.uuid, markForSync: markForSync, handler: handler)
    }
    
    func removeInventoryItem(_ uuid: String, inventoryUuid: String, markForSync: Bool, handler: @escaping (Bool) -> Void) {
        // Needs custom handling because DBRemoveInventoryItem needs the lastUpdate server timestamp and for this we have to retrieve the item from db
        self.doInWriteTransaction({[weak self] realm in
            if let itemToRemove = realm.objects(DBInventoryItem.self).filter(DBInventoryItem.createFilterUuid(uuid)).first {
                self?.removeInventoryItemSync(realm, dbInventoryItem: itemToRemove, markForSync: markForSync)
            }
            return true
            
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func removeInventoryItemSync(_ realm: Realm, dbInventoryItem: DBInventoryItem, markForSync: Bool) {
        if markForSync {
            let toRemoveInventoryItem = DBRemoveInventoryItem(uuid: dbInventoryItem.uuid, inventoryUuid: dbInventoryItem.inventory.uuid, lastServerUpdate: dbInventoryItem.lastServerUpdate)
            realm.add(toRemoveInventoryItem, update: true)
        }
        realm.delete(dbInventoryItem)
    }
    
    // Expected to be executed in do/catch and write block
    func removeInventoryItemsForInventorySync(_ realm: Realm, inventoryUuid: String, markForSync: Bool) -> Bool {
        let dbInventoryItems = realm.objects(DBInventoryItem.self).filter(DBInventoryItem.createFilterInventory(inventoryUuid))
        for dbInventoryItem in dbInventoryItems {
            removeInventoryItemSync(realm, dbInventoryItem: dbInventoryItem, markForSync: markForSync)
        }
        return true
    }
    
    // hm...
    func loadAllInventoryItems(_ handler: @escaping ([InventoryItem]) -> ()) {
        let mapper = {InventoryItemMapper.inventoryItemWithDB($0)}
        self.load(mapper, handler: handler)
    }
    
    func countInventoryItems(_ inventory: DBInventory, handler: @escaping (Int?) -> Void) {
        withRealm({realm in
            realm.objects(DBInventoryItem.self).filter(DBInventoryItem.self.createFilterInventory(inventory.uuid)).count
            }) { (countMaybe: Int?) -> Void in
                if let count = countMaybe {
                    handler(count)
                } else {
                    QL4("No count")
                    handler(nil)
                }
        }
    }
    
    func updateInventoryItemWithIncrementResult(_ incrementResult: RemoteIncrementResult, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            if let storedItem = (realm.objects(DBInventoryItem.self).filter(DBInventoryItem.createFilterUuid(incrementResult.uuid)).first) {
                
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
    
    // Handler returns true if it deleted something, false if there was nothing to delete or an error ocurred.
    func deletePossibleInventoryItemWithUnique(_ productName: String, productBrand: String, inventory: DBInventory, notUuid: String, handler: @escaping (Bool) -> Void) {
        removeReturnCount(DBInventoryItem.createFilter(ProductUnique(name: productName, brand: productBrand), inventoryUuid: inventory.uuid, notUuid: notUuid), handler: {removedCountMaybe in
            if let removedCount = removedCountMaybe {
                if removedCount > 0 {
                    QL2("Found inventory item with same name+brand in list, deleted it. Name: \(productName), brand: \(productBrand), inventory: {\(inventory.uuid), \(inventory.name)}")
                }
            } else {
                QL4("Remove didn't succeed: Name: \(productName), brand: \(productBrand), list: {\(inventory.uuid), \(inventory.name)}")
            }
            handler(removedCountMaybe.map{$0 > 0} ?? false)
        }, objType: DBInventoryItem.self)
    }
    
    
    // MARK: - Direct (no history)
    
    // Add product
    func addToInventory(_ inventory: DBInventory, product: Product, quantity: Int, dirty: Bool, _ handler: @escaping ((inventoryItem: InventoryItem, delta: Int)?) -> Void) {
        doInWriteTransaction({[weak self] realm in
            return self?.addOrIncrementInventoryItem(realm, inventory: inventory, product: product, quantity: quantity, dirty: dirty)
        }, finishHandler: {(inventoryItemWithDeltaMaybe: (inventoryItem: InventoryItem, delta: Int)?) in
            handler(inventoryItemWithDeltaMaybe)
        })
    }

    func addToInventory(_ inventory: DBInventory, productsWithQuantities: [(product: Product, quantity: Int)], dirty: Bool, _ handler: @escaping ([(inventoryItem: InventoryItem, delta: Int)]?) -> Void) {
        doInWriteTransaction({[weak self] realm in guard let weakSelf = self else {return nil}
            
            var addedOrIncrementedInventoryItems: [(inventoryItem: InventoryItem, delta: Int)] = []
            for productsWithQuantity in productsWithQuantities {
                let inventoryItem = weakSelf.addOrIncrementInventoryItem(realm, inventory: inventory, product: productsWithQuantity.product, quantity: productsWithQuantity.quantity, dirty: dirty)
                addedOrIncrementedInventoryItems.append(inventoryItem)
            }
            return addedOrIncrementedInventoryItems
            
            }, finishHandler: {(addedOrIncrementedInventoryItems: [(inventoryItem: InventoryItem, delta: Int)]?) in
                handler(addedOrIncrementedInventoryItems)
        })
    }  
    
    // MARK: - Sync

    fileprivate func addSync(_ realm: Realm, items: [ProductWithQuantityInput], inventory: DBInventory, dirty: Bool) -> [(inventoryItem: InventoryItem, historyItem: HistoryItem)] {
        
        let addedDate = Date().toMillis()
        
        let sharedUser = ProviderFactory().userProvider.mySharedUser ?? DBSharedUser(email: "")
        
        var adddedOrUpdatedItems: [(inventoryItem: InventoryItem, historyItem: HistoryItem)] = []
        
        for item in items {
            
            let addedOrIncrementedInventoryItem = addOrIncrementInventoryItem(realm, inventory: inventory, product: item.product.product, quantity: item.quantity, dirty: dirty)

            let historyItem = HistoryItem(uuid: UUID().uuidString, inventory: inventory, product: item.product.product, addedDate: addedDate, quantity: item.quantity, user: sharedUser, paidPrice: item.product.price)
            let dbHistoryItem = HistoryItemMapper.dbWithHistoryItem(historyItem, dirty: dirty)
            realm.add(dbHistoryItem, update: true)
            
            adddedOrUpdatedItems.append((inventoryItem: addedOrIncrementedInventoryItem.inventoryItem, historyItem: historyItem))
        }
        
        return adddedOrUpdatedItems
    }
    
    fileprivate func addOrIncrementInventoryItem(_ realm: Realm, inventory: DBInventory, product: Product, quantity: Int, dirty: Bool) -> (inventoryItem: InventoryItem, delta: Int) {
        
            // increment if already exists (currently there doesn't seem to be any functionality to do this using Realm so we do it manually)
            let mapper: (DBInventoryItem) -> InventoryItem = {InventoryItemMapper.inventoryItemWithDB($0)}
            let existingInventoryItems: [InventoryItem] = loadSync(realm, mapper: mapper, filter:
                DBInventoryItem.createFilter(product, inventory))
            
            let addedOrIncrementedInventoryItem: InventoryItem = {
                if let existingInventoryItem = existingInventoryItems.first {
                    let existingQuantity = existingInventoryItem.quantity
                    let existingQuantityDelta = existingInventoryItem.quantityDelta
                    
                    return existingInventoryItem.copy(quantity: quantity + existingQuantity, quantityDelta: quantity + existingQuantityDelta)
                    
                } else { // if item doesn't exist there's nothing to increment
                    return InventoryItem(uuid: UUID().uuidString, quantity: quantity, quantityDelta: quantity, product: product, inventory: inventory)
                }
            }()
            
            // save
            let dbInventoryItem = InventoryItemMapper.dbWithInventoryItem(addedOrIncrementedInventoryItem, dirty: dirty)
            realm.add(dbInventoryItem, update: true)
        
        return (inventoryItem: addedOrIncrementedInventoryItem, delta: quantity)
    }
    
    func clearInventoryItemTombstone(_ uuid: String, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveInventoryItem.self, DBRemoveInventoryItem.createFilterUuid(uuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateInventoryItemLastUpdate(_ updateDict: [String: AnyObject], handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateInventoryItemLastUpdate(realm, updateDict: updateDict)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateInventoryItemLastUpdate(_ realm: Realm, updateDict: [String: AnyObject]) {
        realm.create(DBInventoryItem.self, value: updateDict, update: true)
    }

    func updateInventoryItemLastUpdate(_ item: RemoteInventoryItemWithProduct, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateInventoryItemLastUpdate(realm, updateDict: item.inventoryItem.timestampUpdateDict)
            realm.create(DBProduct.self, value: item.product.timestampUpdateDict, update: true)
            realm.create(DBProductCategory.self, value: item.productCategory.timestampUpdateDict, update: true)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateLastSyncTimeStamp(_ items: RemoteInventoryItemsWithHistoryAndDependencies, handler: @escaping (Bool) -> Void) {
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
    
    func updateLastSyncTimeStamp(_ items: RemoteInventoryItemsWithDependencies, handler: @escaping (Bool) -> Void) {
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
            // TODO shared users? - probably not as we can't edit shared users so there's nothing to sync
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
}

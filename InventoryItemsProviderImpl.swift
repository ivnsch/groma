//
//  InventoryItemsProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

class InventoryItemsProviderImpl: InventoryItemsProvider {
   
    let remoteInventoryItemsProvider = RemoteInventoryItemsProvider()
    let dbInventoryProvider = RealmInventoryProvider()
    let memProvider = MemInventoryItemProvider(enabled: true)

    // TODO we are sorting 3x! Optimise this. Ponder if it makes sense to do the server objects sorting in the server (where it can be done at db level)
    func inventoryItems(range: NSRange, inventory: Inventory, fetchMode: ProviderFetchModus = .Both, sortBy: InventorySortBy = .Count, _ handler: ProviderResult<[InventoryItem]> -> ()) {
    
        // TODO!!! use range also in mem cache otherwise comparison below doesn't work
        let memItemsMaybe = memProvider.inventoryItems(inventory)
        if let memItems = memItemsMaybe {
            handler(ProviderResult(status: .Success, sucessResult: memItems.sortBy(sortBy))) // TODO? cache the sorting? is it expensive to sort if already sorted?
            if fetchMode == .MemOnly {
                return
            }
        }
        
        // FIXME: sortBy and range don't work in db (see notes in implementation). For now we have to do this programmatically
        self.dbInventoryProvider.loadInventory(inventory, sortBy: sortBy, range: range) {[weak self] (var dbInventoryItems) in
            
            dbInventoryItems = dbInventoryItems.sortBy(sortBy)
            dbInventoryItems = dbInventoryItems[range]
            
            if (memItemsMaybe.map {$0 != dbInventoryItems}) ?? true { // if memItems is not set or different than db items
                handler(ProviderResult(status: .Success, sucessResult: dbInventoryItems))
                self?.memProvider.overwrite(dbInventoryItems)
            }
            
            self?.remoteInventoryItemsProvider.inventoryItems(inventory) {remoteResult in
                
                if let remoteInventoryItems = remoteResult.successResult {
                    let inventoryItems: [InventoryItem] = remoteInventoryItems.map{InventoryItemMapper.inventoryItemWithRemote($0, inventory: inventory)}.sortBy(sortBy)
                    let inventoryItemsInRange = inventoryItems[range]
                    
                    if (dbInventoryItems != inventoryItemsInRange) {
                        self?.dbInventoryProvider.overwrite(inventoryItems, inventoryUuid: inventory.uuid) {saved in // if items in range are not equal overwritte with all the items
                            handler(ProviderResult(status: .Success, sucessResult: inventoryItemsInRange))
                            self?.memProvider.overwrite(inventoryItems)
                        }
                    }
                    
                } else {
                    DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                }
            }
        }
    }
    
    func countInventoryItems(inventory: Inventory, _ handler: ProviderResult<Int> -> Void) {
        dbInventoryProvider.countInventoryItems(inventory) {countMaybe in
            if let count = countMaybe {
                handler(ProviderResult(status: .Success, sucessResult: count))
            } else {
                QL4("No count")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    
    func addToInventory(inventory: Inventory, itemInput: InventoryItemInput, _ handler: ProviderResult<InventoryItemWithHistoryEntry> -> Void) {
        
        func onHasProduct(product: Product) {
            // TODO! quantity delta I think should increment previous quantity delta not overwrite?
            let inventoryItemWithHistoryEntry = InventoryItemWithHistoryEntry(inventoryItem: InventoryItem(quantity: itemInput.quantity, quantityDelta: itemInput.quantity, product: product, inventory: inventory), historyItemUuid: NSUUID().UUIDString, addedDate: NSDate(), user: ProviderFactory().userProvider.mySharedUser ?? SharedUser(email: ""))
            addToInventory([inventoryItemWithHistoryEntry], remote: true) {result in
                if result.success {
                    handler(ProviderResult(status: .Success, sucessResult: inventoryItemWithHistoryEntry))
                } else {
                    print("Error: InventoryItemsProviderImpl.addToInventory: couldn't add to inventory, result: \(result)")
                    handler(ProviderResult(status: .DatabaseUnknown))
                }
            }
        }
        
        Providers.productProvider.product(itemInput.name, brand: itemInput.brand ?? "") {productResult in
            // TODO consistent handling everywhere of optional results - return always either .Success & Option(None) or .NotFound & non-optional.
            if productResult.success || productResult.status == .NotFound {
                if let product = productResult.sucessResult {
                    onHasProduct(product)
                } else {
                    Providers.productCategoryProvider.categoryWithName(itemInput.category) {result in
                        if let category = result.sucessResult {
                            let product = Product(uuid: NSUUID().UUIDString, name: itemInput.name, price: itemInput.price, category: category, baseQuantity: itemInput.baseQuantity, unit: itemInput.unit, brand: itemInput.brand)
                            onHasProduct(product)
                        } else {
                            let category = ProductCategory(uuid: NSUUID().UUIDString, name: itemInput.category, color: itemInput.categoryColor)
                            let product = Product(uuid: NSUUID().UUIDString, name: itemInput.name, price: itemInput.price, category: category, baseQuantity: itemInput.baseQuantity, unit: itemInput.unit, brand: itemInput.brand)
                            onHasProduct(product)
                        }
                    }
                }
            } else {
                print("Error: InventoryItemsProviderImpl.addToInventory: Error fetching product, result: \(productResult)")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    
    func addToInventory(items: [InventoryItemWithHistoryEntry], remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        
        let memAdded = memProvider.addInventoryItems(items)
        if memAdded {
            handler(ProviderResult(status: .Success))
        }
        
        self.dbInventoryProvider.add(items) {[weak self] saved in

            if !memAdded { // we assume the database result is always == mem result, so if returned from mem already no need to return from db
                if saved {
                    handler(ProviderResult(status: .Success))
                } else {
                    handler(ProviderResult(status: .DatabaseSavingError))
                }
            }
            
            if remote {
                self?.remoteInventoryItemsProvider.addToInventory(items) {remoteResult in
                    
                    if let remoteInventoryItems = remoteResult.successResult {
                        
                        print("DEBUG: add remote inventory items success")
                        
                        
                        // TODO is this comment still relevant?
                        // For now no saving in local database, since there's no logic to increment in the client
                        // TODO in the future we should do the increment in the client, as the app can be used offline-only
                        // then call a sync with the server when we're online, where we either send the pending increments or somehow overwrite with updated items, taking into account timestamps
                        // remember that the inventory has to support merge since it can be shared with other users
                        //                self.dbInventoryProvider.saveInventory(items) {saved in
                        //                    let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status) // return status of remote, for now we don't consider save to db critical - TODO review when focusing on offline mode - in this case at least we have to skip the remote call and db operation is critical
                        //                    handler(ProviderResult(status: providerStatus))
                        //                }
                        
                        
                        self?.dbInventoryProvider.updateLastSyncTimeStamp(remoteInventoryItems) {success in
                        }
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Any>) in
                            QL4("Error addToInventory: \(remoteResult.status)")
                            // if there's a not connection related server error, invalidate cache
                            self?.memProvider.invalidate()
                            handler(result)
                        })
                    }
                }
            }
        }
    }
 
    // For now db only query
    private func findInventoryItem(item: InventoryItem, _ handler: ProviderResult<InventoryItem> -> ()) {
        
        if let memItem = memProvider.inventoryItem(item) {
            handler(ProviderResult(status: .Success, sucessResult: memItem))
            
        } else {
            dbInventoryProvider.findInventoryItem(item) {inventoryItemMaybe in
                if let inventoryItem = inventoryItemMaybe {
                    handler(ProviderResult(status: .Success, sucessResult: inventoryItem))
                } else {
                    handler(ProviderResult(status: .NotFound))
                }
            }
        }
    }
    
    // only db no memory cache or remote, this is currently used only by websocket update (when receive websocket increment, fetch inventory item in order to increment it locally)
    private func findInventoryItem(productUuid: String, inventoryUuid: String, _ handler: ProviderResult<InventoryItem> -> ()) {
        dbInventoryProvider.findInventoryItem(productUuid, inventoryUuid: inventoryUuid) {inventoryItemMaybe in
            if let inventoryItem = inventoryItemMaybe {
                handler(ProviderResult(status: .Success, sucessResult: inventoryItem))
            } else {
                handler(ProviderResult(status: .NotFound))
            }
        }
    }
    
    func incrementInventoryItem(item: InventoryItemIncrement, remote: Bool, _ handler: ProviderResult<InventoryItem> -> ()) {
        findInventoryItem(item.productUuid, inventoryUuid: item.inventoryUuid) {[weak self] result in
            if let inventoryItem = result.sucessResult {
                
                self?.incrementInventoryItem(inventoryItem, delta: item.delta) {result in
                    if result.success {
                        handler(ProviderResult(status: .Success, sucessResult: inventoryItem))
                    } else {
                        handler(ProviderResult(status: .DatabaseSavingError))
                    }
                }
                
            } else {
                print("InventoryItemsProviderImpl.incrementInventoryItem: Didn't find inventory item to increment, for: \(item)")
                handler(ProviderResult(status: .NotFound))
            }
        }
    }

    func incrementInventoryItem(item: InventoryItem, delta: Int, _ handler: ProviderResult<Any> -> ()) {
        
        // Get item from database with updated quantityDelta
        // The reason we do this instead of using the item parameter, is that later doesn't always have valid quantityDelta
        // -> When item is incremented we set back quantityDelta after the server's response, this is NOT communicated to the item in the view controller (so on next increment, the passed quantityDelta is invalid)
        // Which is ok. because the UI must not have logic related with background server update
        // Cleaner would be to create a lightweight InventoryItem version for the UI - without quantityDelta, etc. But this adds extra complexity
        
        let memIncremented = memProvider.incrementInventoryItem(item, delta: delta)
        if memIncremented {
            handler(ProviderResult(status: .Success))
        }
        
        dbInventoryProvider.incrementInventoryItem(item, delta: delta, onlyDelta: false) {[weak self] saved in
            
            if !memIncremented { // we assume the database result is always == mem result, so if returned from mem already no need to return from db
                if saved {
                    handler(ProviderResult(status: .Success))
                } else {
                    handler(ProviderResult(status: .DatabaseSavingError))
                }
            }
            
//            print("SAVED DB \(item)(+delta) in local db. now going to update remote")
            
            self?.remoteInventoryItemsProvider.incrementInventoryItem(item, delta: delta) {remoteResult in
                
                
                if let remoteInventoryItems = remoteResult.successResult {
                    
                    //                    print("SAVED REMOTE will revert delta now in local db for \(item.product.name), with delta: \(-delta)")
                    
                    self?.dbInventoryProvider.updateLastSyncTimeStamp(remoteInventoryItems) {success in
                    
                        // Now that the item was updated in server, set back delta in local database
                        // Note we subtract instead of set to 0, to handle possible parallel requests correctly
                        self?.dbInventoryProvider.incrementInventoryItem(item, delta: -delta, onlyDelta: true) {saved in
                            
                            if saved {
                                //                            self?.findInventoryItem(item) {result in
                                //                                if let newitem = result.sucessResult {
                                //                                    print("3. CONFIRM incremented item: \(item) + \(delta) == \(newitem)")
                                //                                }
                                //                            }
                                
                            } else {
                                print("Error: couln't save remote inventory item")
                            }
                        }
                    }
                    
                } else {
                    DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Any>) in
                        QL4("Error incrementing item: \(item) in remote, result: \(result)")
                        // if there's a not connection related server error, invalidate cache
                        self?.memProvider.invalidate()
                        handler(result)
                    })
                }
            }
        }
    }
    
    func updateInventoryItem(item: InventoryItem, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        memProvider.updateInventoryItem(item)
        
        dbInventoryProvider.saveInventoryItems([item]) {[weak self] updated in
            if !updated {
                self?.memProvider.invalidate()
            }
            
            handler(ProviderResult(status: updated ? .Success : .DatabaseUnknown))
            
            if remote {
                // TODO!!!! server
            }
        }
    }
    
    func removeInventoryItem(productUuid: String, inventoryUuid: String, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        
        let memUpdated = memProvider.removeInventoryItem(productUuid, productUuid: inventoryUuid)
        if memUpdated {
            handler(ProviderResult(status: .Success))
        }
        
        dbInventoryProvider.removeInventoryItem(productUuid, inventoryUuid: inventoryUuid) {[weak self] removed in
            if removed {
                if !memUpdated {
                    handler(ProviderResult(status: .Success))
                }
            } else {
                handler(ProviderResult(status: .DatabaseUnknown))
                self?.memProvider.invalidate()
            }
            
            if remote {
                self?.remoteInventoryItemsProvider.removeInventoryItem(productUuid, inventoryUuid: inventoryUuid) {remoteResult in
                    if !remoteResult.success {
                        DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<Any>) in
                            print("Error removing inventory item in server: productUuid: \(productUuid), inventoryUuid: \(inventoryUuid), result: \(remoteResult)")
                            // if there's a not connection related server error, invalidate cache
                            self?.memProvider.invalidate()
                            handler(remoteResult)
                        }
                    }
                }
            }
        }
    }

    func removeInventoryItem(item: InventoryItem, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        removeInventoryItem(item.product.uuid, inventoryUuid: item.inventory.uuid, remote: remote, handler)
    }
    
    func invalidateMemCache() {
        memProvider.invalidate()
    }
}

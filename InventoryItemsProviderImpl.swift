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
//    let dbInventoryProvider = RealmInventoryProvider()
    let memProvider = MemInventoryItemProvider(enabled: false)

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
        DBProviders.inventoryProvider.loadInventory(inventory, sortBy: sortBy, range: range) {[weak self] (var dbInventoryItems) in
            
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
                        DBProviders.inventoryItemProvider.overwrite(inventoryItems, inventoryUuid: inventory.uuid, clearTombstones: true, dirty: false) {saved in // if items in range are not equal overwritte with all the items
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
        DBProviders.inventoryItemProvider.countInventoryItems(inventory) {countMaybe in
            if let count = countMaybe {
                handler(ProviderResult(status: .Success, sucessResult: count))
            } else {
                QL4("No count")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    
    
    func addToInventory(inventory: Inventory, itemInput: ProductWithQuantityInput, remote: Bool, _ handler: ProviderResult<InventoryItemWithHistoryItem> -> Void) {
        addToInventory(inventory, itemInputs: [itemInput], remote: remote) {result in
            if let addedItem = result.sucessResult?.first {
                handler(ProviderResult(status: .Success, sucessResult: addedItem))
            } else {
                QL4("Couldn't add to inventory: \(result)")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    
    func addToInventory(inventory: Inventory, itemInputs: [ProductWithQuantityInput], remote: Bool, _ handler: ProviderResult<[InventoryItemWithHistoryItem]> -> Void) {
        DBProviders.inventoryItemProvider.addOrIncrementInventoryItemWithInput(itemInputs, inventory: inventory, dirty: remote) {[weak self] addOrIncrementInventoryItemsWithInputMaybe in

            if let addOrIncrementInventoryItemWithInput = addOrIncrementInventoryItemsWithInputMaybe {
                handler(ProviderResult(status: .Success, sucessResult: addOrIncrementInventoryItemWithInput))

                // we can use this instead of invalidating the memory cache. But if possible I think it's better to invalidate to minimise error possibilities, in this case we are moving items from cart to inventory which happens not that offen and also it takes some time to the user to open the inventory screen, so there doesn't seem to be a reason to use mem cache instead of invalidating
//                let memAdded = self?.memProvider.addInventoryItems(addOrIncrementInventoryItemWithInput) ?? false
//                if memAdded {
//                    handler(ProviderResult(status: .Success))
//                }
                self?.invalidateMemCache()
                
                if remote {
                    self?.remoteInventoryItemsProvider.addToInventory(addOrIncrementInventoryItemWithInput) {remoteResult in
                        
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
                            
                            
                            DBProviders.inventoryItemProvider.updateLastSyncTimeStamp(remoteInventoryItems) {success in
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<[InventoryItemWithHistoryItem]>) in
                                QL4("Error addToInventory: \(remoteResult.status)")
                                // if there's a not connection related server error, invalidate cache
                                self?.memProvider.invalidate()
                                handler(result)
                            })
                        }
                    }
                }
                
                
            } else {
                QL4("Error adding to inventory - database didn't return success")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }

    // Outdated implementation, needs now store product
//    func addToInventory(inventory: Inventory, itemInput: InventoryItemInput, _ handler: ProviderResult<InventoryItemWithHistoryEntry> -> Void) {
//    
//        DBProviders.inventoryItemProvider.addOrIncrementInventoryItemWithInput(itemInput, inventory: inventory, delta: itemInput.quantity) {addedInventoryItemWithHistoryMaybe in
//            
//            if let addedInventoryItemWithHistory = addedInventoryItemWithHistoryMaybe {
//                handler(ProviderResult(status: .Success, sucessResult: addedInventoryItemWithHistory))
//            } else {
//                QL4("Error fetching product")
//                handler(ProviderResult(status: .DatabaseUnknown))
//                
//            }
//        }
//    }
    
    func addToInventoryLocal(inventoryItems: [InventoryItem], historyItems: [HistoryItem], dirty: Bool, handler: ProviderResult<Any> -> Void) {
        DBProviders.inventoryItemProvider.saveInventoryAndHistoryItem(inventoryItems, historyItems: historyItems, dirty: dirty) {success in
            if success {
                handler(ProviderResult(status: .Success))
            } else {
                QL4("Error adding to inventory: inventoryItems: \(inventoryItems), historyItems: \(historyItems)")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    
    // For now db only query
    private func findInventoryItem(item: InventoryItem, _ handler: ProviderResult<InventoryItem> -> ()) {
        
        if let memItem = memProvider.inventoryItem(item) {
            handler(ProviderResult(status: .Success, sucessResult: memItem))
            
        } else {
            DBProviders.inventoryItemProvider.findInventoryItem(item) {inventoryItemMaybe in
                if let inventoryItem = inventoryItemMaybe {
                    handler(ProviderResult(status: .Success, sucessResult: inventoryItem))
                } else {
                    handler(ProviderResult(status: .NotFound))
                }
            }
        }
    }
    
    // only db no memory cache or remote, this is currently used only by websocket update (when receive websocket increment, fetch inventory item in order to increment it locally)
    private func findInventoryItem(uuid: String, _ handler: ProviderResult<InventoryItem> -> ()) {
        DBProviders.inventoryItemProvider.findInventoryItem(uuid) {inventoryItemMaybe in
            if let inventoryItem = inventoryItemMaybe {
                handler(ProviderResult(status: .Success, sucessResult: inventoryItem))
            } else {
                handler(ProviderResult(status: .NotFound))
            }
        }
    }

    // TODO this can be optimised, such that we don't have to prefetch the item but increment directly at least in memory    
    func incrementInventoryItem(item: ItemIncrement, remote: Bool, _ handler: ProviderResult<InventoryItem> -> ()) {
        findInventoryItem(item.itemUuid) {[weak self] result in
            if let inventoryItem = result.sucessResult {
                
                self?.incrementInventoryItem(inventoryItem, delta: item.delta, remote: remote) {result in
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

    func incrementInventoryItem(item: InventoryItem, delta: Int, remote: Bool, _ handler: ProviderResult<Int> -> Void) {
        
        // Get item from database with updated quantityDelta
        // The reason we do this instead of using the item parameter, is that later doesn't always have valid quantityDelta
        // -> When item is incremented we set back quantityDelta after the server's response, this is NOT communicated to the item in the view controller (so on next increment, the passed quantityDelta is invalid)
        // Which is ok. because the UI must not have logic related with background server update
        // Cleaner would be to create a lightweight InventoryItem version for the UI - without quantityDelta, etc. But this adds extra complexity
        
        let memIncremented = memProvider.incrementInventoryItem(item, delta: delta)
        if memIncremented {
            handler(ProviderResult(status: .Success))
        }
        
        DBProviders.inventoryItemProvider.incrementInventoryItem(item, delta: delta, onlyDelta: false, dirty: remote) {[weak self] updatedQuantityMaybe in

            if !memIncremented { // we assume the database result is always == mem result, so if returned from mem already no need to return from db
                if let updatedQuantity = updatedQuantityMaybe {
                    handler(ProviderResult(status: .Success, sucessResult: updatedQuantity))
                } else {
                    handler(ProviderResult(status: .DatabaseSavingError))
                }
            }
            
            if remote {
                let itemIncrement = ItemIncrement(delta: delta, itemUuid: item.uuid)
                self?.remoteInventoryItemsProvider.incrementInventoryItem(itemIncrement) {remoteResult in
                    
                    if let incrementResult = remoteResult.successResult {
                        DBProviders.inventoryItemProvider.updateInventoryItemWithIncrementResult(incrementResult) {success in
                            if !success {
                                QL4("Couldn't save increment result for item: \(item), remoteResult: \(remoteResult)")
                            }
                        }
                        
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Int>) in
                            QL4("Error incrementing item: \(item) in remote, result: \(result)")
                            // if there's a not connection related server error, invalidate cache
                            self?.memProvider.invalidate()
                            handler(result)
                        })
                    }
                }
            }
        }
    }
    
    // NOTE: this is not used anymore because we disabled quick add in inventory items, if we enable it again it needs to be modified, update now has to load first possible existent product by unique like in group item/list item update.
    func updateInventoryItem(item: InventoryItem, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        memProvider.updateInventoryItem(item)
        
        DBProviders.inventoryItemProvider.saveInventoryItems([item], dirty: remote) {[weak self] updated in
            if !updated {
                self?.memProvider.invalidate()
            }
            
            handler(ProviderResult(status: updated ? .Success : .DatabaseUnknown))
            
            if remote {
                self?.remoteInventoryItemsProvider.updateInventoryItem(item) {remoteResult in
                    
                    if let remoteInventoryItemsWithDependencies = remoteResult.successResult {

                        DBProviders.inventoryItemProvider.updateInventoryItemLastUpdate(remoteInventoryItemsWithDependencies) {success in
                            if !success {
                                QL4("Couldn't save server timestamp for item: \(item), remoteResult: \(remoteResult)")
                            }
                        }
                        
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Any>) in
                            QL4("Error updating item: \(item) in remote, result: \(result)")
                            // if there's a not connection related server error, invalidate cache
                            self?.memProvider.invalidate()
                            handler(result)
                        })
                    }
                }
            }
        }
    }
    
    func removeInventoryItem(item: InventoryItem, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        removeInventoryItem(item.uuid, inventoryUuid: item.inventory.uuid, remote: remote, handler)
    }
    
    func removeInventoryItem(uuid: String, inventoryUuid: String, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        
        let memUpdated = memProvider.removeInventoryItem(uuid, inventoryUuid: inventoryUuid)
        if memUpdated {
            handler(ProviderResult(status: .Success))
        }
        
        DBProviders.inventoryItemProvider.removeInventoryItem(uuid, inventoryUuid: inventoryUuid, markForSync: true) {[weak self] removed in
            if removed {
                if !memUpdated {
                    handler(ProviderResult(status: .Success))
                }
            } else {
                handler(ProviderResult(status: .DatabaseUnknown))
                self?.memProvider.invalidate()
            }
            
            if remote {
                self?.remoteInventoryItemsProvider.removeInventoryItem(uuid) {remoteResult in
                    if remoteResult.success {
                        DBProviders.inventoryItemProvider.clearInventoryItemTombstone(uuid) {removeTombstoneSuccess in
                            if !removeTombstoneSuccess {
                                QL4("Couldn't delete tombstone for inventory item: \(uuid)::\(inventoryUuid)")
                            }
                        }
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<Any>) in
                            print("Error removing inventory item in uuid: productUuid: \(uuid), inventoryUuid: \(inventoryUuid), result: \(remoteResult)")
                            // if there's a not connection related server error, invalidate cache
                            self?.memProvider.invalidate()
                            handler(remoteResult)
                        }
                    }
                }
            }
        }
    }

    func invalidateMemCache() {
        memProvider.invalidate()
    }
}

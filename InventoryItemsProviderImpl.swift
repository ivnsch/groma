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
    
    func updateInventoryItem(input: InventoryItemInput, updatingInventoryItem: InventoryItem, remote: Bool, _ handler: ProviderResult<(inventoryItem: InventoryItem, replaced: Bool)> -> Void) {
        
        // Remove a possible already existing item with same unique (name+brand) in the same list.
        DBProviders.inventoryItemProvider.deletePossibleInventoryItemWithUnique(input.productPrototype.name, productBrand: input.productPrototype.brand, inventory: updatingInventoryItem.inventory) {foundAndDeletedInventoryItem in
            // Point to possible existing product with same semantic unique / create a new one instead of updating underlying product, which would lead to surprises in other screens.
            Providers.productProvider.mergeOrCreateProduct(input.productPrototype.name, category: input.productPrototype.category, categoryColor: input.productPrototype.categoryColor, brand: input.productPrototype.brand, updateCategory: false) {[weak self] result in
                
                if let product = result.sucessResult {
                    let updatedInventoryItem = updatingInventoryItem.copy(quantity: input.quantity, product: product)
                    self?.updateInventoryItem(updatedInventoryItem, remote: remote) {result in
                        if result.success {
                            handler(ProviderResult(status: .Success, sucessResult: (inventoryItem: updatedInventoryItem, replaced: foundAndDeletedInventoryItem)))
                        } else {
                            QL4("Error updating inventory item: \(result)")
                            handler(ProviderResult(status: result.status))
                        }
                    }
                } else {
                    QL4("Error fetching product: \(result.status)")
                    handler(ProviderResult(status: .DatabaseUnknown))
                }
            }
        }
    }
    
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
    
    func addOrUpdateLocal(inventoryItems: [InventoryItem], _ handler: ProviderResult<Any> -> Void) {
        DBProviders.inventoryItemProvider.saveInventoryItems(inventoryItems, update: true, dirty: false) {[weak self] updated in
            if !updated {
                self?.memProvider.invalidate()
            }
            handler(ProviderResult(status: updated ? .Success : .DatabaseUnknown))
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
    
    // MARK: - Direct (no history)
    
    func addToInventory(inventory: Inventory, product: Product, quantity: Int, remote: Bool, _ handler: ProviderResult<(inventoryItem: InventoryItem, delta: Int)> -> Void) {
        addToInventory(inventory, productsWithQuantities: [(product: product, quantity: quantity)], remote: remote) {result in
            if let addedOrIncrementedInventoryItem = result.sucessResult?.first {
                handler(ProviderResult(status: .Success, sucessResult: addedOrIncrementedInventoryItem))
            } else {
                handler(ProviderResult(status: result.status, sucessResult: nil, error: result.error, errorObj: result.errorObj))
            }
        }
    }
    
    private func addToInventory(inventory: Inventory, productsWithQuantities: [(product: Product, quantity: Int)], remote: Bool, _ handler: ProviderResult<[(inventoryItem: InventoryItem, delta: Int)]> -> Void) {
        DBProviders.inventoryItemProvider.addToInventory(inventory, productsWithQuantities: productsWithQuantities, dirty: remote) {[weak self] addedOrIncrementedInventoryItemsMaybe in
            if let addedOrIncrementedInventoryItems = addedOrIncrementedInventoryItemsMaybe {
                handler(ProviderResult(status: .Success, sucessResult: addedOrIncrementedInventoryItems))
                
                if remote {
                    self?.remoteInventoryItemsProvider.addToInventory(addedOrIncrementedInventoryItems) {remoteResult in
                        if let remoteInventoryItems = remoteResult.successResult {
                            DBProviders.inventoryItemProvider.updateLastSyncTimeStamp(remoteInventoryItems) {success in
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<[(inventoryItem: InventoryItem, delta: Int)]>) in
                                QL4("Error addToInventory: \(remoteResult.status)")
                                // if there's a not connection related server error, invalidate cache
                                self?.memProvider.invalidate()
                                handler(result)
                            })
                        }
                    }
                }
                
            } else {
                QL4("Unknown error adding to inventory in local db, inventory: \(inventory), productsWithQuantities: \(productsWithQuantities)")
                handler(ProviderResult(status: .Unknown))

//                DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
            }
        }
    }

    
    func addToInventory(inventory: Inventory, group: ListItemGroup, remote: Bool, _ handler: ProviderResult<[(inventoryItem: InventoryItem, delta: Int)]> -> Void) {
        Providers.listItemGroupsProvider.groupItems(group, sortBy: .Alphabetic, fetchMode: .MemOnly) {[weak self] result in
            if let groupItems = result.sucessResult {
                let productsWithQuantities: [(product: Product, quantity: Int)] = groupItems.map{($0.product, $0.quantity)}
                self?.addToInventory(inventory, productsWithQuantities: productsWithQuantities, remote: remote, handler)
            } else {
                QL4("Couldn't get items for group: \(group)")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    
    // Add inventory item input
    func addToInventory(inventory: Inventory, itemInput: InventoryItemInput, remote: Bool, _ handler: ProviderResult<(inventoryItem: InventoryItem, delta: Int)> -> Void) {
        
        func onHasProduct(product: Product) {
            addToInventory(inventory, product: product, quantity: 1, remote: remote, handler)
        }
        
        Providers.productProvider.product(itemInput.productPrototype.name, brand: itemInput.productPrototype.brand) {productResult in
            // TODO consistent handling everywhere of optional results - return always either .Success & Option(None) or .NotFound & non-optional.
            if productResult.success || productResult.status == .NotFound {
                if let product = productResult.sucessResult {
                    onHasProduct(product)
                } else {
                    Providers.productCategoryProvider.categoryWithName(itemInput.productPrototype.category) {result in
                        if let category = result.sucessResult {
                            let product = Product(uuid: NSUUID().UUIDString, name: itemInput.productPrototype.name, category: category, brand: itemInput.productPrototype.brand)
                            onHasProduct(product)
                        } else {
                            let category = ProductCategory(uuid: NSUUID().UUIDString, name: itemInput.productPrototype.category, color: itemInput.productPrototype.categoryColor)
                            let product = Product(uuid: NSUUID().UUIDString, name: itemInput.productPrototype.name, category: category, brand: itemInput.productPrototype.brand)
                            onHasProduct(product)
                        }
                    }
                }
            } else {
                QL4("Error fetching product, result: \(productResult)")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
}

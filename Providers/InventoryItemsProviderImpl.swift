//
//  InventoryItemsProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

import RealmSwift

class InventoryItemsProviderImpl: InventoryItemsProvider {
   
    let remoteInventoryItemsProvider = RemoteInventoryItemsProvider()
//    let dbInventoryProvider = RealmInventoryProvider()
    let memProvider = MemInventoryItemProvider(enabled: false)

    // TODO we are sorting 3x! Optimise this. Ponder if it makes sense to do the server objects sorting in the server (where it can be done at db level)
    func inventoryItems(inventory: DBInventory, fetchMode: ProviderFetchModus = .both, sortBy: InventorySortBy = .count, _ handler: @escaping (ProviderResult<Results<InventoryItem>>) -> Void) {
    
        // For now comment mem cache as we can't compare array with Results. We are not using it anyway
//        // TODO!!! use range also in mem cache otherwise comparison below doesn't work
//        let memItemsMaybe = memProvider.inventoryItems(inventory)
//        if let memItems = memItemsMaybe {
//            handler(ProviderResult(status: .success, sucessResult: memItems.sortBy(sortBy))) // TODO? cache the sorting? is it expensive to sort if already sorted?
//            if fetchMode == .memOnly {
//                return
//            }
//        }
        
        // FIXME: sortBy and range don't work in db (see notes in implementation). For now we have to do this programmatically
        DBProv.inventoryProvider.loadInventory(inventory, sortBy: sortBy) {(dbInventoryItems) in
            
//            let dbInventoryItemsSorted = dbInventoryItems.sortBy(sortBy)
//            let dbInventoryItemsInRange = dbInventoryItemsSorted[range]

            
            // For now comment mem cache as we can't compare array with Results. We are not using it anyway
//            if (memItemsMaybe.map {$0 != dbInventoryItems}) ?? true { // if memItems is not set or different than db items
//                handler(ProviderResult(status: .success, sucessResult: dbInventoryItems))
//                _ = self?.memProvider.overwrite(dbInventoryItems)
//            }
            
            if let dbInventoryItems = dbInventoryItems {
                handler(ProviderResult(status: .success, sucessResult: dbInventoryItems))
            } else {
                logger.e("Inventory items is nil")
                handler(ProviderResult(status: .unknown))
            }
            
            
            
            // Disabled while impl. realm sync - access of realm objs here causes wrong thread exception
//            self?.remoteInventoryItemsProvider.inventoryItems(inventory) {remoteResult in
//                
//                if let remoteInventoryItems = remoteResult.successResult {
//                    let inventoryItems: [InventoryItem] = remoteInventoryItems.map{InventoryItemMapper.inventoryItemWithRemote($0, inventory: inventory)}.sortBy(sortBy)
//
//                    if (dbInventoryItems != inventoryItems) {
//                        DBProv.inventoryItemProvider.overwrite(inventoryItems, inventoryUuid: inventory.uuid, clearTombstones: true, dirty: false) {saved in // if items in range are not equal overwritte with all the items
//                            handler(ProviderResult(status: .success, sucessResult: inventoryItems))
//                            _ = self?.memProvider.overwrite(inventoryItems)
//                        }
//                    }
//                    
//                } else {
//                    DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
//                }
//            }
        }
    }
    
    func countInventoryItems(_ inventory: DBInventory, _ handler: @escaping (ProviderResult<Int>) -> Void) {
        DBProv.inventoryItemProvider.countInventoryItems(inventory) {countMaybe in
            if let count = countMaybe {
                handler(ProviderResult(status: .success, sucessResult: count))
            } else {
                logger.e("No count")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func addToInventoryLocal(_ inventoryItems: [InventoryItem], historyItems: [HistoryItem], dirty: Bool, handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.inventoryItemProvider.saveInventoryAndHistoryItem(inventoryItems, historyItems: historyItems, dirty: dirty) {success in
            if success {
                handler(ProviderResult(status: .success))
            } else {
                logger.e("Error adding to inventory: inventoryItems: \(inventoryItems), historyItems: \(historyItems)")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    // For now db only query
    fileprivate func findInventoryItem(_ item: InventoryItem, _ handler: @escaping (ProviderResult<InventoryItem>) -> ()) {
        
        if let memItem = memProvider.inventoryItem(item) {
            handler(ProviderResult(status: .success, sucessResult: memItem))
            
        } else {
            DBProv.inventoryItemProvider.findInventoryItem(item) {inventoryItemMaybe in
                if let inventoryItem = inventoryItemMaybe {
                    handler(ProviderResult(status: .success, sucessResult: inventoryItem))
                } else {
                    handler(ProviderResult(status: .notFound))
                }
            }
        }
    }
    
    // only db no memory cache or remote, this is currently used only by websocket update (when receive websocket increment, fetch inventory item in order to increment it locally)
    fileprivate func findInventoryItem(_ uuid: String, _ handler: @escaping (ProviderResult<InventoryItem>) -> ()) {
        DBProv.inventoryItemProvider.findInventoryItem(uuid) {inventoryItemMaybe in
            if let inventoryItem = inventoryItemMaybe {
                handler(ProviderResult(status: .success, sucessResult: inventoryItem))
            } else {
                handler(ProviderResult(status: .notFound))
            }
        }
    }

    // TODO this can be optimised, such that we don't have to prefetch the item but increment directly at least in memory    
    func incrementInventoryItem(_ item: ItemIncrement, remote: Bool, _ handler: @escaping (ProviderResult<InventoryItem>) -> ()) {
        findInventoryItem(item.itemUuid) {[weak self] result in
            if let inventoryItem = result.sucessResult {
                
                self?.incrementInventoryItem(inventoryItem, delta: item.delta, remote: remote, realmData: nil) {result in
                    if result.success {
                        handler(ProviderResult(status: .success, sucessResult: inventoryItem))
                    } else {
                        handler(ProviderResult(status: .databaseSavingError))
                    }
                }
                
            } else {
                print("InventoryItemsProviderImpl.incrementInventoryItem: Didn't find inventory item to increment, for: \(item)")
                handler(ProviderResult(status: .notFound))
            }
        }
    }

    func incrementInventoryItem(_ item: InventoryItem, delta: Float, remote: Bool, realmData: RealmData?, _ handler: @escaping (ProviderResult<Float>) -> Void) {
        
        // Get item from database with updated quantityDelta
        // The reason we do this instead of using the item parameter, is that later doesn't always have valid quantityDelta
        // -> When item is incremented we set back quantityDelta after the server's response, this is NOT communicated to the item in the view controller (so on next increment, the passed quantityDelta is invalid)
        // Which is ok. because the UI must not have logic related with background server update
        // Cleaner would be to create a lightweight InventoryItem version for the UI - without quantityDelta, etc. But this adds extra complexity
        
        let memIncremented = memProvider.incrementInventoryItem(item, delta: delta)
        if memIncremented {
            handler(ProviderResult(status: .success))
        }
        
        DBProv.inventoryItemProvider.incrementInventoryItem(item, delta: delta, realmData: realmData, onlyDelta: false, dirty: remote) {dbResult in

            if !memIncremented { // we assume the database result is always == mem result, so if returned from mem already no need to return from db
                if let updatedQuantity = dbResult.sucessResult {
                    handler(ProviderResult(status: .success, sucessResult: updatedQuantity))
                    
                    // Disabled while impl. realm sync - access of realm objs here causes wrong thread exception
//                    if remote {
//                        let itemIncrement = ItemIncrement(delta: delta, itemUuid: item.uuid)
//                        self?.remoteInventoryItemsProvider.incrementInventoryItem(itemIncrement) {remoteResult in
//                            
//                            if let incrementResult = remoteResult.successResult {
//                                DBProv.inventoryItemProvider.updateInventoryItemWithIncrementResult(incrementResult) {success in
//                                    if !success {
//                                        logger.e("Couldn't save increment result for item: \(item), remoteResult: \(remoteResult)")
//                                    }
//                                }
//                                
//                            } else {
//                                DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Int>) in
//                                    logger.e("Error incrementing item: \(item) in remote, result: \(result)")
//                                    // if there's a not connection related server error, invalidate cache
//                                    self?.memProvider.invalidate()
//                                    handler(result)
//                                })
//                            }
//                        }
//                    }
                    
                    
                } else {
                    if dbResult.status == .notFound {
                        // When swiping many times quickly we get requests to increment items that have already been deleted, which triggers error alert - this may require a better fix but for now we ignore not found status
                        logger.w("Item to increment not found: \(item), returning success anyway")
                        handler(ProviderResult(status: .success))
                    } else {
                        logger.e("Unknown error incrementing inventory item: \(item), delta: \(delta)")
                        handler(ProviderResult(status: .databaseSavingError))
                    }
                }
            }
        }
    }
    
    func updateInventoryItem(_ input: InventoryItemInput, updatingInventoryItem: InventoryItem, remote: Bool, realmData: RealmData, _ handler: @escaping (ProviderResult<UpdateInventoryItemResult>) -> Void) {
        let result = DBProv.inventoryItemProvider.updateNew(inventoryItem: updatingInventoryItem, input: input, realmData: realmData)
        result.onOk {result in
            handler(ProviderResult(status: .success, sucessResult: result))
        }.onErr {error in
            logger.e("Error updating inventory item: \(error)")
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
    
    func updateInventoryItem(_ item: InventoryItem, remote: Bool, realmData: RealmData, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        _ = memProvider.updateInventoryItem(item)
        
        let updated = DBProv.inventoryItemProvider.saveSync(inventoryItems: [item], realmData: realmData)
        if !updated {
            memProvider.invalidate()
        }
        
        handler(ProviderResult(status: updated ? .success : .databaseUnknown))
            
            // Disabled while impl. realm sync - access of realm objs here causes wrong thread exception
//            if remote {
//                self?.remoteInventoryItemsProvider.updateInventoryItem(item) {remoteResult in
//                    
//                    if let remoteInventoryItemsWithDependencies = remoteResult.successResult {
//
//                        DBProv.inventoryItemProvider.updateInventoryItemLastUpdate(remoteInventoryItemsWithDependencies) {success in
//                            if !success {
//                                logger.e("Couldn't save server timestamp for item: \(item), remoteResult: \(remoteResult)")
//                            }
//                        }
//                        
//                    } else {
//                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Any>) in
//                            logger.e("Error updating item: \(item) in remote, result: \(result)")
//                            // if there's a not connection related server error, invalidate cache
//                            self?.memProvider.invalidate()
//                            handler(result)
//                        })
//                    }
//                }
//            }
    }
    
    func addOrUpdateLocal(_ inventoryItems: [InventoryItem], _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.inventoryItemProvider.saveInventoryItems(inventoryItems, update: true, dirty: false) {[weak self] updated in
            if !updated {
                self?.memProvider.invalidate()
            }
            handler(ProviderResult(status: updated ? .success : .databaseUnknown))
        }
    }
    
    func removeInventoryItem(_ item: InventoryItem, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        removeInventoryItem(item.uuid, inventoryUuid: item.inventory.uuid, remote: remote, realmData: nil, handler)
    }
    
    func removeInventoryItem(_ uuid: String, inventoryUuid: String, remote: Bool, realmData: RealmData?, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        
        let memUpdated = memProvider.removeInventoryItem(uuid, inventoryUuid: inventoryUuid)
        if memUpdated {
            handler(ProviderResult(status: .success))
        }
        
        if DBProv.inventoryItemProvider.removeInventoryItem(uuid, inventoryUuid: inventoryUuid, markForSync: true, realmData: realmData) {
            if !memUpdated {
                handler(ProviderResult(status: .success))
            }
        } else {
            handler(ProviderResult(status: .databaseUnknown))
            memProvider.invalidate()
        }
            
            // Disabled while impl. realm sync - access of realm objs here causes wrong thread exception
//            if remote {
//                self?.remoteInventoryItemsProvider.removeInventoryItem(uuid) {remoteResult in
//                    if remoteResult.success {
//                        DBProv.inventoryItemProvider.clearInventoryItemTombstone(uuid) {removeTombstoneSuccess in
//                            if !removeTombstoneSuccess {
//                                logger.e("Couldn't delete tombstone for inventory item: \(uuid)::\(inventoryUuid)")
//                            }
//                        }
//                    } else {
//                        DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<Any>) in
//                            logger.w("Error removing inventory item in uuid: productUuid: \(uuid), inventoryUuid: \(inventoryUuid), result: \(remoteResult)")
//                            // When swiping many items quickly it may be that we send multiple requests to delete same item, so we get not found sometimes. Ignore.
//                            // TODO is this really necessary - what can be do client side to prevent trying to delete same item multiple times?
//                            if remoteResult.status != .notFound {
//                                self?.memProvider.invalidate()
//                                handler(remoteResult)
//                            } else {
//                                logger.w("Inventory item to delete was not found in the server, ignoring")
//                            }
//                        }
//                    }
//                }
//            }
    }

    func invalidateMemCache() {
        memProvider.invalidate()
    }
    
    // MARK: - Direct (no history)
    
    func addToInventory(_ inventory: DBInventory, product: QuantifiableProduct, quantity: Float, remote: Bool, realmData: RealmData?, _ handler: @escaping (ProviderResult<(inventoryItem: InventoryItem, delta: Float, isNew: Bool)>) -> Void) {
        let inventory: DBInventory = inventory.copy()
        let product: QuantifiableProduct = product.copy()
        addToInventory(inventory, productsWithQuantities: [(product: product, quantity: quantity)], remote: remote, realmData: realmData) {result in
            if let addedOrIncrementedInventoryItem = result.sucessResult?.first {
                handler(ProviderResult(status: .success, sucessResult: addedOrIncrementedInventoryItem))
            } else {
                handler(ProviderResult(status: result.status, sucessResult: nil, error: result.error, errorObj: result.errorObj))
            }
        }
    }
    
    fileprivate func addToInventory(_ inventory: DBInventory, productsWithQuantities: [(product: QuantifiableProduct, quantity: Float)], remote: Bool, realmData: RealmData?, _ handler: @escaping (ProviderResult<[(inventoryItem: InventoryItem, delta: Float, isNew: Bool)]>) -> Void) {
        let inventory: DBInventory = inventory.copy()
        let productsWithQuantities: [(product: QuantifiableProduct, quantity: Float)] = productsWithQuantities.map{($0.product.copy(), $0.quantity)}
        
        DBProv.inventoryItemProvider.addToInventory(inventory, productsWithQuantities: productsWithQuantities, dirty: remote, realmData: realmData) {addedOrIncrementedInventoryItemsMaybe in
            if let addedOrIncrementedInventoryItems = addedOrIncrementedInventoryItemsMaybe {
                handler(ProviderResult(status: .success, sucessResult: addedOrIncrementedInventoryItems))

                // Disabled while impl. realm sync - access of realm objs here causes wrong thread exception
//                if remote {
//                    self?.remoteInventoryItemsProvider.addToInventory(addedOrIncrementedInventoryItems) {remoteResult in
//                        if let remoteInventoryItems = remoteResult.successResult {
//                            DBProv.inventoryItemProvider.updateLastSyncTimeStamp(remoteInventoryItems) {success in
//                            }
//                        } else {
//                            DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<[(inventoryItem: InventoryItem, delta: Int)]>) in
//                                logger.e("Error addToInventory: \(remoteResult.status)")
//                                // if there's a not connection related server error, invalidate cache
//                                self?.memProvider.invalidate()
//                                handler(result)
//                            })
//                        }
//                    }
//                }
                
            } else {
                logger.e("Unknown error adding to inventory in local db, inventory: \(inventory), productsWithQuantities: \(productsWithQuantities)")
                handler(ProviderResult(status: .unknown))

//                DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
            }
        }
    }

    
    func addToInventory(_ inventory: DBInventory, group: ProductGroup, remote: Bool, _ handler: @escaping (ProviderResult<[(inventoryItem: InventoryItem, delta: Float)]>) -> Void) {
        logger.e("Outdated")
        handler(ProviderResult(status: .unknown))
//        Prov.listItemGroupsProvider.groupItems(group, sortBy: .alphabetic, fetchMode: .memOnly) {[weak self] result in
//            if let groupItems = result.sucessResult {
//                if groupItems.isEmpty {
//                    handler(ProviderResult(status: .isEmpty))
//                } else {
//                    let productsWithQuantities: [(product: QuantifiableProduct, quantity: Float)] = groupItems.map{($0.product, $0.quantity)}
//                    self?.addToInventory(inventory, productsWithQuantities: productsWithQuantities, remote: remote, realmData: nil, handler)
//                }
//            } else {
//                logger.e("Couldn't get items for group: \(group)")
//                handler(ProviderResult(status: .databaseUnknown))
//            }
//        }
    }
    
    // Add inventory item input
    func addToInventory(_ inventory: DBInventory, itemInput: InventoryItemInput, remote: Bool, realmData: RealmData, _ handler: @escaping (ProviderResult<(inventoryItem: InventoryItem, delta: Float, isNew: Bool)>) -> Void) {
        
        func onHasProduct(_ product: QuantifiableProduct) {
            addToInventory(inventory, product: product, quantity: 1, remote: remote, realmData: nil, handler)
        }
        
        Prov.productProvider.quantifiableProduct(QuantifiableProductUnique(name: itemInput.productPrototype.name, brand: itemInput.productPrototype.brand, unit: itemInput.productPrototype.unit, baseQuantity: itemInput.productPrototype.baseQuantity, secondBaseQuantity: itemInput.productPrototype.secondBaseQuantity)) {productResult in
            // TODO consistent handling everywhere of optional results - return always either .Success & Option(None) or .NotFound & non-optional.
            if productResult.success || productResult.status == .notFound {
                if let product = productResult.sucessResult {
                    onHasProduct(product)
                    
                } else { // no quantifiable product with unique, create it
                    
                    Prov.productProvider.mergeOrCreateProduct(prototype: itemInput.productPrototype, updateCategory: true, updateItem: true, realmData: realmData) { (result: ProviderResult<(QuantifiableProduct, Bool)>) in
                        if let quantifiableProduct = result.sucessResult {
                            self.addToInventory(inventory, product: quantifiableProduct.0, quantity: 1, remote: remote, realmData: realmData, handler)
                        }
                    }
                }
            } else {
                logger.e("Error fetching product, result: \(productResult)")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
}

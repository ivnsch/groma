//
//  InventoryItemsProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class InventoryItemsProviderImpl: InventoryItemsProvider {
   
    let remoteInventoryItemsProvider = RemoteInventoryItemsProvider()
    let dbInventoryProvider = RealmInventoryProvider()
    let memProvider = MemInventoryItemProvider(enabled: true)

    // TODO we are sorting 3x! Optimise this. Ponder if it makes sense to do the server objects sorting in the server (where it can be done at db level)
    func inventoryItems(range: NSRange, inventory: Inventory, fetchMode: ProviderFetchModus = .Both, sortBy: InventorySortBy = .Count, _ handler: ProviderResult<[InventoryItem]> -> ()) {
    
        let memItemsMaybe = memProvider.inventoryItems(inventory)
        if let memItems = memItemsMaybe {
            handler(ProviderResult(status: .Success, sucessResult: memItems.sortBy(sortBy))) // TODO? cache the sorting? is it expensive to sort if already sorted?
            if fetchMode == .MemOnly {
                return
            }
        }
        
        // FIXME: sortBy and range don't work in db (see notes in implementation). For now we have to do this programmatically
        self.dbInventoryProvider.loadInventory(sortBy, range: range) {[weak self] (var dbInventoryItems) in
            
            dbInventoryItems = dbInventoryItems.sortBy(sortBy)
            dbInventoryItems = dbInventoryItems[range]
            
            if (memItemsMaybe.map {$0 != dbInventoryItems}) ?? true { // if memItems is not set or different than db items
                handler(ProviderResult(status: .Success, sucessResult: dbInventoryItems))
                self?.memProvider.overwrite(dbInventoryItems)
            }
            
            self?.remoteInventoryItemsProvider.inventoryItems(inventory) {remoteResult in
                
                if let remoteInventoryItems = remoteResult.successResult {
                    let inventoryItems: [InventoryItem] = remoteInventoryItems.map{InventoryItemMapper.inventoryItemWithRemote($0, inventory: inventory)}.sortBy(sortBy)
                    
                    // if there's no cached list or there's a difference, overwrite the cached list
                    if (dbInventoryItems != inventoryItems) {
                        self?.dbInventoryProvider.saveInventoryItems(inventoryItems) {saved in
                            if fetchMode == .Both {
                                handler(ProviderResult(status: .Success, sucessResult: inventoryItems))
                            }
                            
                            self?.memProvider.overwrite(inventoryItems)
                        }
                    }
                    
                } else {
                    DefaultRemoteErrorHandler.handle(remoteResult.status, handler: handler)
                }
            }
        }
    }
    
    func addToInventory(inventory: Inventory, items: [InventoryItemWithHistoryEntry], _ handler: ProviderResult<Any> -> ()) {
        
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
            
            self?.remoteInventoryItemsProvider.addToInventory(inventory, inventoryItems: items) {remoteResult in
                
                if let _ = remoteResult.successResult {
                    
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
                    
                    
                    
                } else {
                    print("Error addToInventory: \(remoteResult.status)")
                    // (what do we do with server invalid data error? do we remove the record from the client's database? which kind of error do we show to the client!? in any case this has to be sent to error monitoring, very clearly and detailed
                    DefaultRemoteErrorHandler.handle(remoteResult.status) {(remoteResult: ProviderResult<Any>) in
                        // if there's a not connection related server error, invalidate cache
                        self?.memProvider.invalidate()
                        handler(remoteResult)
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
                
                if remoteResult.success {
                    
//                    print("SAVED REMOTE will revert delta now in local db for \(item.product.name), with delta: \(-delta)")
                    
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
                    
                } else {
                    print("Error incrementing item: \(item) in remote, result: \(remoteResult)")
                    DefaultRemoteErrorHandler.handle(remoteResult.status)  {(remoteResult: ProviderResult<Any>) in
                        // if there's a not connection related server error, invalidate cache
                        self?.memProvider.invalidate()
                        handler(remoteResult)
                    }
                }
            }
        }
    }
    
    func updateInventoryItem(inventory: Inventory, item: InventoryItem) {
        // TODO
//        self.cdProvider.updateInventoryItem(item, handler: {try in
//        })
    }
    
    func removeInventoryItem(item: InventoryItem, _ handler: ProviderResult<Any> -> ()) {
        
        let memUpdated = memProvider.removeInventoryItem(item)
        if memUpdated {
            handler(ProviderResult(status: .Success))
        }
        
        dbInventoryProvider.removeInventoryItem(item) {[weak self] removed in
            if removed {
                if !memUpdated {
                    handler(ProviderResult(status: .Success))
                }
            } else {
                handler(ProviderResult(status: .DatabaseUnknown))
                self?.memProvider.invalidate()
            }
            
            self?.remoteInventoryItemsProvider.removeInventoryItem(item) {remoteResult in
                if !remoteResult.success {
                    print("Error removing inventory item in server: \(item), result: \(remoteResult)")
                    DefaultRemoteErrorHandler.handle(remoteResult.status)  {(remoteResult: ProviderResult<Any>) in
                        // if there's a not connection related server error, invalidate cache
                        self?.memProvider.invalidate()
                        handler(remoteResult)
                    }
                }
            }
        }
    }
    
    func invalidateMemCache() {
        memProvider.invalidate()
    }
}

//
//  InventoryProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class InventoryProviderImpl: InventoryProvider {
   
    private let remoteProvider = RemoteInventoryProvider()
    private let remoteInventoryItemsProvider = RemoteInventoryItemsProvider()
    private let dbInventoryProvider = RealmInventoryProvider()

    func inventories(handler: ProviderResult<[Inventory]> -> ()) {
        self.dbInventoryProvider.loadInventories {dbInventories in
            handler(ProviderResult(status: .Success, sucessResult: dbInventories))
            
            self.remoteProvider.inventories {remoteResult in
                
                if let remoteInventories = remoteResult.successResult {
                    let inventories: [Inventory] = remoteInventories.map{InventoryMapper.inventoryWithRemote($0)}
                    
                    // if there's no cached list or there's a difference, overwrite the cached list
                    if dbInventories != inventories {
                        
                        self.dbInventoryProvider.saveInventories(inventories, update: true) {saved in
                            if saved {
                                handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: inventories))
                                
                            } else {
                                print("Error updating inventories - dbListsMaybe is nil")
                            }
                        }
                    }
                    
                } else {
                    print("get remote inventories no success, status: \(remoteResult.status)")
                    DefaultRemoteErrorHandler.handle(remoteResult.status, handler: handler)
                }
            }
        }
    }
    
    func firstInventory(handler: ProviderResult<Inventory> -> ()) {
        inventories {result in
            if let inventories = result.sucessResult {
                if let firstInventory = inventories.first {
                    handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: firstInventory))
                } else {
                    print("Warn firstInventory, success but there's no inventory")
                    handler(ProviderResult(status: .NotFound))
                }
            } else {
                handler(ProviderResult(status: result.status))
            }
        }
    }
    
    func syncInventories(handler: (ProviderResult<Any>) -> ()) {
        
        self.dbInventoryProvider.loadInventories {dbInventories in

            // TODO send only items that are new or updated, currently sending everything
            // new -> doesn't have lastServerUpdate, updated -> lastUpdate > lastServerUpdate
            var inventories: [Inventory] = []
            var toRemove: [Inventory] = []
            for inventory in dbInventories {
                if inventory.removed {
                    toRemove.append(inventory)
                } else {
                    // Send only "dirty" items
                    // Note assumption - lastUpdate can't be smaller than lastServerUpdate, so with != we mean >
                    // when we receive sync result we reset lastUpdate of all items to lastServerUpdate, from there on lastUpdate can become only bigger
                    // and when the items are not synced yet, lastServerUpdate is nil so != will also be true
                    // Note also that the server can handle not-dirty items, we filter them just to reduce the payload
                    if inventory.lastUpdate != inventory.lastServerUpdate {
                        inventories.append(inventory)
                    }
                }
            }
            
            self.remoteProvider.syncInventories(inventories, toRemove: toRemove) {remoteResult in
                
                if let syncResult = remoteResult.successResult {
                    
                    // for now overwrite all. In the future we should do a timestamp check here also for the case that user does an update while the sync service is being called
                    // since we support background sync, this should not be neglected
                    let serverInventory = syncResult.items.map{InventoryMapper.dbWithInventory($0)}
                    self.dbInventoryProvider.overwrite(serverInventory) {success in
                        if success {
                            handler(ProviderResult(status: .Success))
                        } else {
                            handler(ProviderResult(status: .DatabaseSavingError))
                        }
                        return
                    }
                    
                } else {
                    DefaultRemoteErrorHandler.handle(remoteResult.status, handler: handler)
                }
            }
        }
    }
    
//    func addInventoryWithItems(inventory: Inventory, items: [InventoryItem], _ handler: ProviderResult<Any> -> ()) {
//        
//        self.dbInventoryProvider.saveInventory(inventory) {saved in
//            if saved {
//                self.dbInventoryProvider.saveInventoryItems(items) {saved in
//                    if saved {
//                        handler(ProviderResult(status: .Success))
//                        
//                        // background
//                        self.remoteProvider.addInventory(inventory) {remoteResult in
//                            if remoteResult.success {
//                                self.remoteInventoryItemsProvider.addToInventory(inventory, inventoryItems: items) {remoteResult in
//                                    if !remoteResult.success {
//                                        print("Error: remoteInventoryItemsProvider.addToInventory failed: \(remoteResult.status)") // TODO handle, when should we remove the item from local DB, when should we send a msg to error monitoring etc.
//                                    }
//                                }
//                            } else {
//                                    print("Error: remoteProvider.addInventory failed: \(remoteResult.status)") // TODO handle, when should we remove the item from local DB, when should we send a msg to error monitoring etc.
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    func addInventory(inventory: Inventory, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        self.dbInventoryProvider.saveInventory(inventory) {[weak self] saved in
            if saved {
                handler(ProviderResult(status: .Success))
                if remote {
                    // background TODO should we sync like now only when local DB save was success or also when it failed
                    self?.remoteProvider.addInventory(inventory) {remoteResult in
                        if !remoteResult.success {
                            print("Error: addInventory background sync failed: \(remoteResult.status)") // TODO handle, when should we remove the item from local DB, when should we send a msg to error monitoring etc.
                            DefaultRemoteErrorHandler.handle(remoteResult.status, handler: handler)
                        }
                    }
                }

            } else {
                handler(ProviderResult(status: .DatabaseSavingError))
            }
        }
    }
    
    func updateInventory(inventory: Inventory, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        dbInventoryProvider.saveInventory(inventory, update: true) {[weak self] saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseUnknown))
            if remote {
                self?.remoteProvider.updateInventory(inventory) {remoteResult in
                    DefaultRemoteErrorHandler.handle(remoteResult.status, handler: handler)
                }
            }
        }
    }
    
    func syncInventoriesWithInventoryItems(handler: (ProviderResult<[Any]> -> ())) {
        
        self.dbInventoryProvider.loadInventories {dbInventories in
            
            self.dbInventoryProvider.loadAllInventoryItems {dbInventoryItems in

                let inventoriesSync = SyncUtils.toInventoriesSync(dbInventories, dbInventoryItems: dbInventoryItems)

                self.remoteProvider.syncInventoriesWithInventoryItems(inventoriesSync) {remoteResult in
                    
                    if let syncResult = remoteResult.successResult {
                        
                        self.dbInventoryProvider.saveInventoriesSyncResult(syncResult) {success in
                            if success {
                                handler(ProviderResult(status: .Success))
                            } else {
                                handler(ProviderResult(status: .DatabaseSavingError))
                            }
                        }
                        
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult.status, handler: handler)
                    }
                }
            }
        }
    }

}

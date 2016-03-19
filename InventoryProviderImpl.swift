//
//  InventoryProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

class InventoryProviderImpl: InventoryProvider {
   
    private let remoteProvider = RemoteInventoryProvider()
    private let remoteInventoryItemsProvider = RemoteInventoryItemsProvider()
    private let dbInventoryProvider = RealmInventoryProvider()

    func inventories(remote: Bool = true, _ handler: ProviderResult<[Inventory]> -> ()) {
        self.dbInventoryProvider.loadInventories {dbInventories in
            handler(ProviderResult(status: .Success, sucessResult: dbInventories))
            
            if remote {
                self.remoteProvider.inventories {remoteResult in
                    
                    if let remoteInventories = remoteResult.successResult {
                        let inventories: [Inventory] = remoteInventories.map{InventoryMapper.inventoryWithRemote($0)}
                        let sortedInventories = inventories.sortedByOrder()
                        
                        if dbInventories != sortedInventories {
                            
                            self.dbInventoryProvider.overwrite(sortedInventories, clearTombstones: true) {saved in
                                if saved {
                                    handler(ProviderResult(status: .Success, sucessResult: sortedInventories))
                                    
                                } else {
                                    QL4("Error updating inventories - dbListsMaybe is nil")
                                }
                            }
                        }
                        
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                    }
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
                        
                        if let remoteInventory = remoteResult.successResult {
                            self?.dbInventoryProvider.updateLastSyncTimeStamp(remoteInventory) {success in
                                if !success {
                                    QL4("Error storing last update timestamp")
                                }
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler) // TODO handle, when should we remove the item from local DB, when should we send a msg to error monitoring etc.
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
                    if let remoteInventory = remoteResult.successResult {
                        self?.dbInventoryProvider.updateLastSyncTimeStamp(remoteInventory) {success in
                            if !success {
                                QL4("Error storing last update timestamp")
                            }
                        }
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                    }
                }
            }
        }
    }
    
    func updateInventoriesOrder(orderUpdates: [OrderUpdate], remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        DBProviders.inventoryProvider.updateInventoriesOrder(orderUpdates) {[weak self] success in
            if success {
                handler(ProviderResult(status: .Success))
                
                if remote {
                    self?.remoteProvider.updateInventoriesOrder(orderUpdates) {remoteResult in
                        // Note: no server update timetamps here, because server implementation details, more info see note in RemoteOrderUpdate
                        if !remoteResult.success {
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                        }
                    }
                }
            } else {
                QL4("Error updating inventories order in local database, orderUpdates: \(orderUpdates)")
                handler(ProviderResult(status: .Unknown))
            }
        }
    }
    
    func removeInventory(inventory: Inventory, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        removeInventory(inventory.uuid, remote: remote, handler)
    }

    func removeInventory(uuid: String, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        dbInventoryProvider.removeInventory(uuid, markForSync: true) {[weak self] removed in
            handler(ProviderResult(status: removed ? .Success : .DatabaseUnknown))
            if removed {
                if remote {
                    self?.remoteProvider.removeInventory(uuid) {remoteResult in
                        if remoteResult.success {
                            self?.dbInventoryProvider.clearInventoryTombstone(uuid) {removeTombstoneSuccess in
                                if !removeTombstoneSuccess {
                                    QL4("Couldn't delete tombstone for inventory: \(uuid)")
                                }
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                        }
                    }
                }
            } else {
                QL4("DB remove didn't succeed")
            }
        }
    }
    
    // TODO is this still needed?
    func syncInventoriesWithInventoryItems(handler: (ProviderResult<[Any]> -> ())) {
        
        self.dbInventoryProvider.loadInventories {dbInventories in
            
            DBProviders.inventoryItemProvider.loadAllInventoryItems {dbInventoryItems in

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
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                    }
                }
            }
        }
    }
    
    
    func acceptInvitation(invitation: RemoteInventoryInvitation, _ handler: ProviderResult<Any> -> Void) {
        remoteProvider.acceptInvitation(invitation) {remoteResult in
            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
        }
    }
    
    func rejectInvitation(invitation: RemoteInventoryInvitation, _ handler: ProviderResult<Any> -> Void) {
        remoteProvider.rejectInvitation(invitation) {remoteResult in
            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
        }
    }
}

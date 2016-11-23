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
   
    fileprivate let remoteProvider = RemoteInventoryProvider()
    fileprivate let remoteInventoryItemsProvider = RemoteInventoryItemsProvider()
    fileprivate let dbInventoryProvider = RealmInventoryProvider()

    func inventories(_ remote: Bool = true, _ handler: @escaping (ProviderResult<[Inventory]>) -> ()) {
        self.dbInventoryProvider.loadInventories {dbInventories in
            
            let sotedDBInventories = dbInventories.sortedByOrder() // include name in sorting to guarantee equal ordering with remote result, in case of duplicate order fields
            
            handler(ProviderResult(status: .success, sucessResult: sotedDBInventories))
            
            if remote {
                self.remoteProvider.inventories {remoteResult in
                    
                    if let remoteInventories = remoteResult.successResult {
                        let inventories: [Inventory] = remoteInventories.map{InventoryMapper.inventoryWithRemote($0)}
                        let sortedInventories = inventories.sortedByOrder()
                        
                        if sotedDBInventories != sortedInventories {
                            
                            self.dbInventoryProvider.overwrite(sortedInventories, clearTombstones: true, dirty: false) {saved in
                                if saved {
                                    handler(ProviderResult(status: .success, sucessResult: sortedInventories))
                                    
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
    
    func firstInventory(_ handler: @escaping (ProviderResult<Inventory>) -> ()) {
        inventories {result in
            if let inventories = result.sucessResult {
                if let firstInventory = inventories.first {
                    handler(ProviderResult(status: .success, sucessResult: firstInventory))
                } else {
                    print("Warn firstInventory, success but there's no inventory")
                    handler(ProviderResult(status: .notFound))
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
    
    func addInventory(_ inventory: Inventory, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        self.dbInventoryProvider.saveInventory(inventory, dirty: remote) {[weak self] saved in
            if saved {
                handler(ProviderResult(status: .success))
                if remote {
                    self?.remoteProvider.addInventory(inventory) {remoteResult in
                        
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

            } else {
                handler(ProviderResult(status: .databaseSavingError))
            }
        }
    }
    
    func updateInventory(_ inventory: Inventory, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        dbInventoryProvider.saveInventory(inventory, update: true, dirty: remote) {[weak self] saved in
            handler(ProviderResult(status: saved ? .success : .databaseUnknown))
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
    
    func updateInventoriesOrder(_ orderUpdates: [OrderUpdate], remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        // dirty == remote: if we want to do a remote call, it means the update is client triggered (opposed to e.g. processing a websocket message) which means the data is not in the server yet, which means it's dirty.
        DBProviders.inventoryProvider.updateInventoriesOrder(orderUpdates, dirty: remote) {[weak self] success in
            if success {
                handler(ProviderResult(status: .success))
                
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
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    func removeInventory(_ inventory: Inventory, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        removeInventory(inventory.uuid, remote: remote, handler)
    }

    func removeInventory(_ uuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        dbInventoryProvider.removeInventory(uuid, markForSync: remote) {[weak self] removed in
            handler(ProviderResult(status: removed ? .success : .databaseUnknown))
            if removed {
                
                Notification.send(.ListRemoved, dict: [NotificationKey.list: uuid as AnyObject])

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
    
    func acceptInvitation(_ invitation: RemoteInventoryInvitation, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        remoteProvider.acceptInvitation(invitation) {remoteResult in
            if remoteResult.success {
                QL1("Accept inventory invitation success")
                handler(ProviderResult(status: .success))
            } else {
                DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
            }
        }
    }
    
    func rejectInvitation(_ invitation: RemoteInventoryInvitation, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        remoteProvider.rejectInvitation(invitation) {remoteResult in
            if remoteResult.success {
                QL1("Reject inventory invitation success")
            } else {
                DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
            }
        }
    }
    
    func findInvitedUsers(_ listUuid: String, _ handler: @escaping (ProviderResult<[SharedUser]>) -> Void) {
        remoteProvider.findInvitedUsers(listUuid) {remoteResult in
            if let remoteSharedUsers = remoteResult.successResult {
                let sharedUsers: [SharedUser] = remoteSharedUsers.map{SharedUserMapper.sharedUserWithRemote($0)}
                handler(ProviderResult(status: .success, sucessResult: sharedUsers))
            } else {
                DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
            }
        }
    }
}

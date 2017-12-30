//
//  InventoryProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

import RealmSwift

class InventoryProviderImpl: InventoryProvider {
   
    fileprivate let remoteProvider = RemoteInventoryProvider()
    fileprivate let remoteInventoryItemsProvider = RemoteInventoryItemsProvider()
    fileprivate let dbInventoryProvider = RealmInventoryProvider()

    //////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////
    
    // NEW
    
    func inventories(_ remote: Bool = true, _ handler: @escaping (ProviderResult<RealmSwift.List<DBInventory>>) -> Void) {
        DBProv.inventoryProvider.loadInventories {dbInventories in
            
            handler(ProviderResult(status: .success, sucessResult: dbInventories))
            
            // Disabled while impl. realm sync
            //            if remote {
            //                self.remoteProvider.inventories {remoteResult in
            //
            //                    if let remoteInventories = remoteResult.successResult {
            //                        let inventories: [DBInventory] = remoteInventories.map{InventoryMapper.inventoryWithRemote($0)}
            //                        let sortedInventories = inventories.sortedByOrder()
            //
            //                        if sotedDBInventories != sortedInventories {
            //
            //                            self.dbInventoryProvider.overwrite(sortedInventories, clearTombstones: true, dirty: false) {saved in
            //                                if saved {
            //                                    handler(ProviderResult(status: .success, sucessResult: sortedInventories))
            //
            //                                } else {
            //                                    logger.e("Error updating inventories - dbListsMaybe is nil")
            //                                }
            //                            }
            //                        }
            //
            //                    } else {
            //                        DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
            //                    }
            //                }
            //            }
        }
    }
   
    public func add(_ inventory: DBInventory, inventories: RealmSwift.List<DBInventory>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.inventoryProvider.add(inventory, inventories: inventories, notificationToken: notificationToken) { result in
            handler(ProviderResult(status: result.providerStatus))
        }
    }
    
    public func update(_ inventory: DBInventory, input: InventoryInput, inventories: RealmSwift.List<DBInventory>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.inventoryProvider.update(inventory, input: input, inventories: inventories, notificationToken: notificationToken) {success in
            handler(ProviderResult(status: success ? .success : .databaseUnknown))
        }
    }
    
    public func move(from: Int, to: Int, inventories: RealmSwift.List<DBInventory>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.inventoryProvider.move(from: from, to: to, inventories: inventories, notificationToken: notificationToken) {success in
            handler(ProviderResult(status: success ? .success : .databaseUnknown))
        }
    }
    
    public func delete(index: Int, inventories: RealmSwift.List<DBInventory>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.inventoryProvider.delete(index: index, inventories: inventories, notificationToken: notificationToken) {success in
            handler(ProviderResult(status: success ? .success : .databaseUnknown))
        }
    }
    
    //////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////

    
    func inventoriesRealm(_ remote: Bool, _ handler: @escaping (ProviderResult<Results<DBInventory>>) -> Void) {
        dbInventoryProvider.loadInventoriesRealm {dbInventories in
            if let dbInventories = dbInventories {
                handler(ProviderResult(status: .success, sucessResult: dbInventories))
            } else {
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    func firstInventory(_ handler: @escaping (ProviderResult<DBInventory>) -> ()) {
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
    
//    func addInventoryWithItems(inventory: DBInventory, items: [InventoryItem], _ handler: ProviderResult<Any> -> ()) {
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
    
    func addInventory(_ inventory: DBInventory, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        
        DBProv.inventoryProvider.add(inventory, notificationToken: nil) { result in
            if result.isSuccess {
                handler(ProviderResult(status: .success))
                
                // Remove all backend code?
                //                if remote {
                //                    self?.remoteProvider.addInventory(inventory) {remoteResult in
                //
                //                        if let remoteInventory = remoteResult.successResult {
                //                            self?.dbInventoryProvider.updateLastSyncTimeStamp(remoteInventory) {success in
                //                                if !success {
                //                                    logger.e("Error storing last update timestamp")
                //                                }
                //                            }
                //                        } else {
                //                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                //                        }
                //                    }
                //                }
                
            } else {
                handler(ProviderResult(status: result.providerStatus))
            }
        }
    }
    
    func updateInventory(_ inventory: DBInventory, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        dbInventoryProvider.saveInventory(inventory, update: true, dirty: remote) {saved in
            handler(ProviderResult(status: saved ? .success : .databaseUnknown))
            
            // Remove all backend code?
//            if remote {
//                self?.remoteProvider.updateInventory(inventory) {remoteResult in
//                    if let remoteInventory = remoteResult.successResult {
//                        self?.dbInventoryProvider.updateLastSyncTimeStamp(remoteInventory) {success in
//                            if !success {
//                                logger.e("Error storing last update timestamp")
//                            }
//                        }
//                    } else {
//                        DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
//                    }
//                }
//            }
        }
    }
    
    func updateInventoriesOrder(_ orderUpdates: [OrderUpdate], withoutNotifying: [NotificationToken], realm: Realm?, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        // dirty == remote: if we want to do a remote call, it means the update is client triggered (opposed to e.g. processing a websocket message) which means the data is not in the server yet, which means it's dirty.
        DBProv.inventoryProvider.updateInventoriesOrder(orderUpdates, withoutNotifying: withoutNotifying, realm: realm, dirty: remote) {success in
            if success {
                handler(ProviderResult(status: .success))
            
                // Remove all backend code?
//                if remote {
//                    self?.remoteProvider.updateInventoriesOrder(orderUpdates) {remoteResult in
//                        // Note: no server update timetamps here, because server implementation details, more info see note in RemoteOrderUpdate
//                        if !remoteResult.success {
//                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
//                        }
//                    }
//                }
            } else {
                logger.e("Error updating inventories order in local database, orderUpdates: \(orderUpdates)")
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    func removeInventory(_ inventory: DBInventory, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        removeInventory(inventory.uuid, remote: remote, handler)
    }

    func removeInventory(_ uuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        dbInventoryProvider.removeInventory(uuid, markForSync: remote) {removed in
            handler(ProviderResult(status: removed ? .success : .databaseUnknown))
            if removed {
                
                Notification.send(.ListRemoved, dict: [NotificationKey.list: uuid as AnyObject])

                // Remove all backend code?
//                if remote {
//                    self?.remoteProvider.removeInventory(uuid) {remoteResult in
//                        if remoteResult.success {
//                            self?.dbInventoryProvider.clearInventoryTombstone(uuid) {removeTombstoneSuccess in
//                                if !removeTombstoneSuccess {
//                                    logger.e("Couldn't delete tombstone for inventory: \(uuid)")
//                                }
//                            }
//                        } else {
//                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
//                        }
//                    }
//                }
            } else {
                logger.e("DB remove didn't succeed")
            }
        }
    }
    
    func acceptInvitation(_ invitation: RemoteInventoryInvitation, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        remoteProvider.acceptInvitation(invitation) {remoteResult in
            if remoteResult.success {
                logger.v("Accept inventory invitation success")
                handler(ProviderResult(status: .success))
            } else {
                DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
            }
        }
    }
    
    func rejectInvitation(_ invitation: RemoteInventoryInvitation, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        remoteProvider.rejectInvitation(invitation) {remoteResult in
            if remoteResult.success {
                logger.v("Reject inventory invitation success")
            } else {
                DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
            }
        }
    }
    
    func findInvitedUsers(_ listUuid: String, _ handler: @escaping (ProviderResult<[DBSharedUser]>) -> Void) {
        remoteProvider.findInvitedUsers(listUuid) {remoteResult in
            if let remoteSharedUsers = remoteResult.successResult {
                let sharedUsers: [DBSharedUser] = remoteSharedUsers.map{SharedUserMapper.sharedUserWithRemote($0)}
                handler(ProviderResult(status: .success, sucessResult: sharedUsers))
            } else {
                DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
            }
        }
    }
}

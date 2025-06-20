//
//  ListProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 08/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

import RealmSwift

class ListProviderImpl: ListProvider {
   
    let remoteListProvider = RemoteListItemProvider()
    
    //////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////
    
    // NEW
    
    // Note: programmatic sorting 2x. But users normally have only a few lists so it's ok
    func lists(_ remote: Bool = true, _ handler: @escaping (ProviderResult<RealmSwift.List<List>>) -> Void) {
        DBProv.listProvider.loadLists {lists in
            if let lists = lists {
                handler(ProviderResult(status: .success, sucessResult: lists))
            } else {
                logger.e("Couldn't load lists")
                handler(ProviderResult(status: .unknown, sucessResult: lists))
            }
            
            // Disabled while impl. realm sync
            //            if remote {
            //                self.remoteListProvider.lists {remoteResult in
            //
            //                    if let remoteLists = remoteResult.successResult {
            //                        let lists = ListMapper.listsWithRemote(remoteLists)
            //
            //                        // if there are no local lists or there's a difference, overwrite the local lists
            //                        if sortedLists != lists {
            //
            //                            DBProv.listProvider.overwriteLists(lists, clearTombstones: true) {saved in
            //                                if saved {
            //                                    if !sortedLists.equalsExcludingSyncAttributes(lists) { // the sync attributes are not relevant to the ui so notify ui only if sth else changed
            //                                        handler(ProviderResult(status: .success, sucessResult: lists))
            //                                    }
            //                                } else {
            //                                    logger.e("Error overwriting lists - couldn't save")
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
    
    public func add(_ list: List, lists: RealmSwift.List<List>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.listProvider.add(list, lists: lists, notificationToken: notificationToken) { result in
            handler(ProviderResult(status: result.providerStatus))
        }
    }
    
    public func update(_ list: List, input: ListInput, lists: RealmSwift.List<List>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.listProvider.update(list, input: input, lists: lists, notificationToken: notificationToken) {success in
            handler(ProviderResult(status: success ? .success : .databaseUnknown))
        }
    }
    
    public func move(from: Int, to: Int, lists: RealmSwift.List<List>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.listProvider.move(from: from, to: to, lists: lists, notificationToken: notificationToken) {success in
            handler(ProviderResult(status: success ? .success : .databaseUnknown))
        }
    }
    
    public func delete(index: Int, lists: RealmSwift.List<List>, notificationToken: NotificationToken, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.listProvider.delete(index: index, lists: lists, notificationToken: notificationToken) {success in
            handler(ProviderResult(status: success ? .success : .databaseUnknown))
        }
    }
    
    //////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////
    
    func list(_ listUuid: String, _ handler: @escaping (ProviderResult<List>) -> ()) {
        // return the saved object, to get object with generated id
        DBProv.listProvider.loadList(listUuid) {dbListMaybe in
            if let dbList = dbListMaybe {
                handler(ProviderResult(status: .success, sucessResult: dbList))
                
            } else {
                logger.e("Couldn't loadList: \(listUuid)")
                handler(ProviderResult(status: .notFound))
            }
            
        }
    }

    func add(_ list: List, remote: Bool, _ handler: @escaping (ProviderResult<List>) -> Void) {
        
        DBProv.listProvider.add(list, notificationToken: nil) { result in
            if result.isSuccess {
                handler(ProviderResult(status: .success, sucessResult: list))
            } else {
                handler(ProviderResult(status: result.providerStatus))
            }
        }
            
        
//        // TODO ensure that in add list case the list is persisted / is never deleted
//        // it can be that the user adds it, and we add listitem to tableview immediately to make it responsive
//        // but then the background service call fails so nothing is added in the server or db and the user adds 100 items to the list and restarts the app and everything is lost!
//        // remote -> dirty: if we want to upload to server, it means item has to be marked as dirty
//        DBProv.listProvider.saveList(list, dirty: remote, handler: {saved in
//            
//            if saved {
//                handler(ProviderResult(status: .success, sucessResult: list))
//            } else {
//                handler(ProviderResult(status: .databaseUnknown))
//            }
//
//            // Disabled while impl. realm sync - access of realm objs here causes wrong thread exception
////            if remote {
////                self?.remoteListProvider.add(list, handler: {remoteResult in
////                    if let timestamp = remoteResult.successResult {
////                        // We update only the timestamp of the lists as the server doesn't update the inventory, only sends it, as dependency. TODO (server/client) use timestamp-only response.
////                        DBProvrealProvider.updateLastSyncTimeStamp([list], timestamp: timestamp) {success in
////                            if !success {
////                                logger.e("Error storing last update timestamp")
////                            }
////                        }
////                    } else {
////                        DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
////                    }
////                })
////            }
//        })
    }

    func update(_ list: List, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        update([list], remote: remote, handler)
    }
    
    // TODO! do we still need to update a list array? this use case should be covered now with updateListsOrder?
    func update(_ lists: [List], remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        DBProv.listProvider.saveLists(lists, update: true, dirty: remote) {updated in
            handler(ProviderResult(status: updated ? .success : .databaseSavingError))
            if updated {
                // Disabled while impl. realm sync
//                if remote {
//                    self?.remoteListProvider.update(lists) {remoteResult in
//                        if let timestamp = remoteResult.successResult {
//                            DBProv.listProvider.updateLastSyncTimeStamp(lists, timestamp: timestamp) {success in
//                                if !success {
//                                    logger.e("Error storing last update timestamp")
//                                }
//                            }
//                        } else {
//                            DefaultRemoteErrorHandler.handle(remoteResult) {(remoteResult: ProviderResult<Any>) in
//                                logger.e(remoteResult)
//                            }
//                        }
//                    }
//                }
            } else {
                logger.e("DB update didn't succeed")
            }
        }
    }
    
    func updateListsOrder(_ orderUpdates: [OrderUpdate], remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        // dirty == remote: if we want to do a remote call, it means the update is client triggered (opposed to e.g. processing a websocket message) which means the data is not in the server yet, which means it's dirty.
        DBProv.listProvider.updateListsOrder(orderUpdates, dirty: remote) {success in
            if success {
                handler(ProviderResult(status: .success))
                
                // Disabled while impl. realm sync
//                if remote {
//                    self?.remoteListProvider.updateListsOrder(orderUpdates) {remoteResult in
//                        // Note: no server update timetamps here, because server implementation details, more info see note in RemoteOrderUpdate
//                        if !remoteResult.success {
//                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
//                        }
//                    }
//                }
            } else {
                logger.e("Error updating lists order in local database, orderUpdates: \(orderUpdates)")
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    func remove(_ list: List, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        remove(list.uuid, remote: remote, handler)
    }

    func remove(_ listUuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        
        // TODO ensure that in add list case the list is persisted / is never deleted
        // it can be that the user adds it, and we add listitem to tableview immediately to make it responsive
        // but then the background service call fails so nothing is added in the server or db and the user adds 100 items to the list and restarts the app and everything is lost!
        
        // TODO when removing and item doesn't exist shouldn't we return an error (currently at least local db returns success)?
        DBProv.listProvider.remove(listUuid, markForSync: remote, handler: {removed in
            handler(ProviderResult(status: removed ? .success : .databaseSavingError))
            if removed {
                // Disabled while impl. realm sync
//                if remote {
//                    self?.remoteListProvider.remove(listUuid) {remoteResult in
//                        if remoteResult.success {
//                            DBProv.listProvider.clearListTombstone(listUuid) {removeTombstoneSuccess in
//                                if !removeTombstoneSuccess {
//                                    logger.e("Couldn't delete tombstone for list: \(listUuid)")
//                                }
//                            }
//                        } else {
//                            DefaultRemoteErrorHandler.handle(remoteResult) {(remoteResult: ProviderResult<Any>) in
//                                logger.e(remoteResult)
//                            }
//                        }
//                    }
//                }
            } else {
                logger.e("DB remove didn't succeed")
            }
        })
    }
    
    func acceptInvitation(_ invitation: RemoteListInvitation, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        remoteListProvider.acceptInvitation(invitation) {remoteResult in
            if remoteResult.success {
                logger.v("Accept list invitation success")
                handler(ProviderResult(status: .success))
            } else {
                DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
            }
        }
    }
    
    func rejectInvitation(_ invitation: RemoteListInvitation, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        remoteListProvider.rejectInvitation(invitation) {remoteResult in
            if remoteResult.success {
                logger.v("Reject list invitation success")
            } else {
                DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
            }
            
        }
    }
    
    func findInvitedUsers(_ listUuid: String, _ handler: @escaping (ProviderResult<[DBSharedUser]>) -> Void) {
        remoteListProvider.findInvitedUsers(listUuid) {remoteResult in
            if let remoteSharedUsers = remoteResult.successResult {
                let sharedUsers: [DBSharedUser] = remoteSharedUsers.map{SharedUserMapper.sharedUserWithRemote($0)}
                handler(ProviderResult(status: .success, sucessResult: sharedUsers))
            } else {
                DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
            }
        }
    }
}

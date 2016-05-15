//
//  ListProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 08/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

class ListProviderImpl: ListProvider {
   
    let remoteListProvider = RemoteListItemProvider()
    
    // Note: programmatic sorting 2x. But users normally have only a few lists so it's ok
    func lists(remote: Bool = true, _ handler: ProviderResult<[List]> -> ()) {
        DBProviders.listProvider.loadLists{dbLists in
            
            let sortedDBLists = dbLists.sortedByOrder()
            
            handler(ProviderResult(status: .Success, sucessResult: sortedDBLists))
            
            if remote {
                self.remoteListProvider.lists {remoteResult in
                    
                    if let remoteLists = remoteResult.successResult {
                        let lists = ListMapper.listsWithRemote(remoteLists)
                        
                        // if there are no local lists or there's a difference, overwrite the local lists
                        if sortedDBLists != lists {
                            
                            DBProviders.listProvider.overwriteLists(lists, clearTombstones: true) {saved in
                                if saved {
                                    if !sortedDBLists.equalsExcludingSyncAttributes(lists) { // the sync attributes are not relevant to the ui so notify ui only if sth else changed
                                        handler(ProviderResult(status: .Success, sucessResult: lists))
                                    }
                                } else {
                                    QL4("Error overwriting lists - couldn't save")
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
    
    func list(listUuid: String, _ handler: ProviderResult<List> -> ()) {
        // return the saved object, to get object with generated id
        DBProviders.listProvider.loadList(listUuid) {dbListMaybe in
            if let dbList = dbListMaybe {
                handler(ProviderResult(status: .Success, sucessResult: dbList))
                
            } else {
                QL4("Couldn't loadList: \(listUuid)")
                handler(ProviderResult(status: .NotFound))
            }
            
        }
    }

    func add(list: List, remote: Bool, _ handler: ProviderResult<List> -> ()) {
        
        // TODO ensure that in add list case the list is persisted / is never deleted
        // it can be that the user adds it, and we add listitem to tableview immediately to make it responsive
        // but then the background service call fails so nothing is added in the server or db and the user adds 100 items to the list and restarts the app and everything is lost!
        // remote -> dirty: if we want to upload to server, it means item has to be marked as dirty
        DBProviders.listProvider.saveList(list, dirty: remote, handler: {[weak self] saved in
            
            if saved {
                handler(ProviderResult(status: .Success, sucessResult: list))
            } else {
                handler(ProviderResult(status: .DatabaseUnknown))
            }
            
            if remote {
                self?.remoteListProvider.add(list, handler: {remoteResult in
                    if let timestamp = remoteResult.successResult {
                        // We update only the timestamp of the lists as the server doesn't update the inventory, only sends it, as dependency. TODO (server/client) use timestamp-only response.
                        DBProviders.listProvider.updateLastSyncTimeStamp([list], timestamp: timestamp) {success in
                            if !success {
                                QL4("Error storing last update timestamp")
                            }
                        }
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                    }
                })
            }
        })
    }

    func update(list: List, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        update([list], remote: remote, handler)
    }
    
    // TODO! do we still need to update a list array? this use case should be covered now with updateListsOrder?
    func update(lists: [List], remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        DBProviders.listProvider.saveLists(lists, update: true, dirty: remote) {[weak self] updated in
            handler(ProviderResult(status: updated ? .Success : .DatabaseSavingError))
            if updated {
                if remote {
                    self?.remoteListProvider.update(lists) {remoteResult in
                        if let timestamp = remoteResult.successResult {
                            DBProviders.listProvider.updateLastSyncTimeStamp(lists, timestamp: timestamp) {success in
                                if !success {
                                    QL4("Error storing last update timestamp")
                                }
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(remoteResult) {(remoteResult: ProviderResult<Any>) in
                                QL4(remoteResult)
                            }
                        }
                    }
                }
            } else {
                QL4("DB update didn't succeed")
            }
        }
    }
    
    func updateListsOrder(orderUpdates: [OrderUpdate], remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        // dirty == remote: if we want to do a remote call, it means the update is client triggered (opposed to e.g. processing a websocket message) which means the data is not in the server yet, which means it's dirty.
        DBProviders.listProvider.updateListsOrder(orderUpdates, dirty: remote) {[weak self] success in
            if success {
                handler(ProviderResult(status: .Success))
                
                if remote {
                    self?.remoteListProvider.updateListsOrder(orderUpdates) {remoteResult in
                        // Note: no server update timetamps here, because server implementation details, more info see note in RemoteOrderUpdate
                        if !remoteResult.success {
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                        }
                    }
                }
            } else {
                QL4("Error updating lists order in local database, orderUpdates: \(orderUpdates)")
                handler(ProviderResult(status: .Unknown))
            }
        }
    }
    
    func remove(list: List, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        remove(list.uuid, remote: remote, handler)
    }

    func remove(listUuid: String, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        
        // TODO ensure that in add list case the list is persisted / is never deleted
        // it can be that the user adds it, and we add listitem to tableview immediately to make it responsive
        // but then the background service call fails so nothing is added in the server or db and the user adds 100 items to the list and restarts the app and everything is lost!
        
        // TODO when removing and item doesn't exist shouldn't we return an error (currently at least local db returns success)?
        DBProviders.listProvider.remove(listUuid, markForSync: remote, handler: {[weak self] removed in
            handler(ProviderResult(status: removed ? .Success : .DatabaseSavingError))
            if removed {
                if remote {
                    self?.remoteListProvider.remove(listUuid) {remoteResult in
                        if remoteResult.success {
                            DBProviders.listProvider.clearListTombstone(listUuid) {removeTombstoneSuccess in
                                if !removeTombstoneSuccess {
                                    QL4("Couldn't delete tombstone for list: \(listUuid)")
                                }
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(remoteResult) {(remoteResult: ProviderResult<Any>) in
                                QL4(remoteResult)
                            }
                        }
                    }
                }
            } else {
                QL4("DB remove didn't succeed")
            }
        })
    }
    
    func acceptInvitation(invitation: RemoteListInvitation, _ handler: ProviderResult<Any> -> Void) {
        remoteListProvider.acceptInvitation(invitation) {remoteResult in
            if remoteResult.success {
                QL1("Accept list invitation success")
                handler(ProviderResult(status: .Success))
            } else {
                DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
            }
        }
    }
    
    func rejectInvitation(invitation: RemoteListInvitation, _ handler: ProviderResult<Any> -> Void) {
        remoteListProvider.rejectInvitation(invitation) {remoteResult in
            if remoteResult.success {
                QL1("Reject list invitation success")
            } else {
                DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
            }
            
        }
    }
    
    func findInvitedUsers(listUuid: String, _ handler: ProviderResult<[SharedUser]> -> Void) {
        remoteListProvider.findInvitedUsers(listUuid) {remoteResult in
            if let remoteSharedUsers = remoteResult.successResult {
                let sharedUsers: [SharedUser] = remoteSharedUsers.map{SharedUserMapper.sharedUserWithRemote($0)}
                handler(ProviderResult(status: .Success, sucessResult: sharedUsers))
            } else {
                DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
            }
        }
    }
}
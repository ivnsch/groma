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
    let dbProvider = RealmListItemProvider()
    
    // Note: programmatic sorting 2x. But users normally have only a few lists so it's ok
    func lists(remote: Bool = true, _ handler: ProviderResult<[List]> -> ()) {
        self.dbProvider.loadLists{(var dbLists) in
            
            dbLists = dbLists.sortedByOrder()
            
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbLists))
            
            if remote {
                self.remoteListProvider.lists {remoteResult in
                    
                    if let remoteLists = remoteResult.successResult {
                        let lists: [List] = ListMapper.listsWithRemote(remoteLists)
                        
                        // if there's no cached list or there's a difference, overwrite the cached list
                        if dbLists != lists {
                            
                            // the lists come fresh from the server so we have to set the dirty flag to false
                            let listsNoDirty: [DBList] = lists.map{ListMapper.dbWithList($0, dirty: false)}
                            self.dbProvider.saveLists(listsNoDirty, update: true) {saved in
                                if saved {
                                    handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: lists))
                                    
                                } else {
                                    print("Error updating lists - dbListsMaybe is nil")
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
    
    // TODO is this used? Also what id, is it uuid?
    func list(listId: String, _ handler: ProviderResult<List> -> ()) {
        // return the saved object, to get object with generated id
        self.dbProvider.loadList(listId) {dbListMaybe in
            if let dbList = dbListMaybe {
                handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbList))
                
            } else {
                print("Error: couldn't loadList: \(listId)")
                handler(ProviderResult(status: ProviderStatusCode.NotFound))
            }
            
        }
    }

    func add(list: List, remote: Bool, _ handler: ProviderResult<List> -> ()) {
        
        // TODO ensure that in add list case the list is persisted / is never deleted
        // it can be that the user adds it, and we add listitem to tableview immediately to make it responsive
        // but then the background service call fails so nothing is added in the server or db and the user adds 100 items to the list and restarts the app and everything is lost!
        dbProvider.saveList(list, handler: {[weak self] saved in
            
            if saved {
                handler(ProviderResult(status: .Success, sucessResult: list))
            } else {
                handler(ProviderResult(status: .DatabaseUnknown))
            }
            
            if remote {
                self?.remoteListProvider.add(list, handler: {remoteResult in
                    if let remoteLists = remoteResult.successResult {
                        self?.dbProvider.updateLastSyncTimeStamp(remoteLists) {success in
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
    
    func update(lists: [List], remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        dbProvider.saveLists(lists, update: true) {[weak self] updated in
            handler(ProviderResult(status: updated ? .Success : .DatabaseSavingError))
            if updated {
                if remote {
                    self?.remoteListProvider.update(lists) {remoteResult in
                        if let remoteLists = remoteResult.successResult {
                            self?.dbProvider.updateLastSyncTimeStamp(remoteLists) {success in
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
    
    func remove(list: List, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        remove(list.uuid, remote: remote, handler)
    }

    func remove(listUuid: String, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        
        // TODO ensure that in add list case the list is persisted / is never deleted
        // it can be that the user adds it, and we add listitem to tableview immediately to make it responsive
        // but then the background service call fails so nothing is added in the server or db and the user adds 100 items to the list and restarts the app and everything is lost!
        
        // TODO when removing and item doesn't exist shouldn't we return an error (currently at least local db returns success)?
        self.dbProvider.remove(listUuid, handler: {[weak self] removed in
            handler(ProviderResult(status: removed ? .Success : .DatabaseSavingError))
            if removed {
                if remote {
                    self?.remoteListProvider.remove(listUuid) {remoteResult in
                        if !remoteResult.success {
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
    
    // TODO do we still need this?
    func syncListsWithListItems(handler: (ProviderResult<[Any]> -> ())) {
        
        self.dbProvider.loadLists {dbLists in
            
            self.dbProvider.loadAllListItems {dbListItems in

                let listsSync = SyncUtils.toListsSync(dbLists, dbListItems: dbListItems)

                self.remoteListProvider.syncListsWithListItems(listsSync) {remoteResult in
                    
                    if let syncResult = remoteResult.successResult {
                        
                        self.dbProvider.saveListsSyncResult(syncResult) {success in
                            if success {
                                handler(ProviderResult(status: .Success))
                            } else {
                                handler(ProviderResult(status: .DatabaseSavingError))
                            }
                        }
                        
                    } else {
                        print("Error: sync list with list items: \(remoteResult)")
                        let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status)
                        handler(ProviderResult(status: providerStatus))
                    }
                }
            }
        }
    }
    
    func acceptInvitation(invitation: RemoteListInvitation, _ handler: ProviderResult<Any> -> Void) {
        remoteListProvider.acceptInvitation(invitation) {remoteResult in
            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
        }
    }
    
    func rejectInvitation(invitation: RemoteListInvitation, _ handler: ProviderResult<Any> -> Void) {
        remoteListProvider.rejectInvitation(invitation) {remoteResult in
            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
        }
    }
}
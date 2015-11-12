//
//  ListProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 08/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class ListProviderImpl: ListProvider {
   
    let remoteListProvider = RemoteListItemProvider()
    let dbProvider = RealmListItemProvider()
    
    // Note: programmatic sorting 2x. But users normally have only a few lists so it's ok
    func lists(handler: ProviderResult<[List]> -> ()) {
        self.dbProvider.loadLists{(var dbLists) in
            
            dbLists = dbLists.sortedByOrder()
            
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbLists))
            
            self.remoteListProvider.lists {remoteResult in
                
                if let remoteLists = remoteResult.successResult {
                    let lists: [List] = remoteLists.map{ListMapper.ListWithRemote($0)}.sortedByOrder()
                    
                    // if there's no cached list or there's a difference, overwrite the cached list
                    if dbLists != lists {
                        
                        self.dbProvider.saveLists(lists, update: true) {saved in
                            if saved {
                                handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: lists))
                                
                            } else {
                                print("Error updating lists - dbListsMaybe is nil")
                            }
                        }
                    }
                    
                } else {
                    print("get remote lists no success, status: \(remoteResult.status)")
                    DefaultRemoteErrorHandler.handle(remoteResult.status, handler: handler)
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

    func add(list: List, _ handler: ProviderResult<List> -> ()) {
        
        // TODO ensure that in add list case the list is persisted / is never deleted
        // it can be that the user adds it, and we add listitem to tableview immediately to make it responsive
        // but then the background service call fails so nothing is added in the server or db and the user adds 100 items to the list and restarts the app and everything is lost!
        dbProvider.saveList(list, handler: {saved in
            
            if saved {
                handler(ProviderResult(status: .Success, sucessResult: list))
            } else {
                handler(ProviderResult(status: .DatabaseUnknown))
            }
            
            self.remoteListProvider.add(list, handler: {remoteResult in
                
                if !remoteResult.success {
                    print("error adding the remote list: \(remoteResult.status)")
                    DefaultRemoteErrorHandler.handle(remoteResult.status, handler: handler)
                }
            })
        })
    }
    
    func update(lists: [List], _ handler: ProviderResult<Any> -> ()) {
        dbProvider.saveLists(lists, update: true) {updated in
            handler(ProviderResult(status: updated ? .Success : .DatabaseSavingError))
        }
    }
    
    func remove(list: List, _ handler: ProviderResult<Any> -> ()) {
        
        // TODO ensure that in add list case the list is persisted / is never deleted
        // it can be that the user adds it, and we add listitem to tableview immediately to make it responsive
        // but then the background service call fails so nothing is added in the server or db and the user adds 100 items to the list and restarts the app and everything is lost!
        
        self.dbProvider.remove(list, handler: {removed in
            handler(ProviderResult(status: removed ? .Success : .DatabaseSavingError))
            
            // TODO remote
        })
    }

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
                        print("Error: sync list with list items: \(remoteResult.status)")
                        DefaultRemoteErrorHandler.handle(remoteResult.status, handler: handler)
                    }
                }
            }
        }
    }
}
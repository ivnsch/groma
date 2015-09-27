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

    func add(list: List, _ handler: ProviderResult<List> -> ()) {
        
        // TODO ensure that in add list case the list is persisted / is never deleted
        // it can be that the user adds it, and we add listitem to tableview immediately to make it responsive
        // but then the background service call fails so nothing is added in the server or db and the user adds 100 items to the list and restarts the app and everything is lost!
        
        self.dbProvider.saveList(list, handler: {saved in
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: list))
            
            self.remoteListProvider.add(list, handler: {remoteResult in
                
                if !remoteResult.success {
                    print("error adding the remote list: \(remoteResult.status)")
                    DefaultRemoteErrorHandler.handle(remoteResult.status, handler: handler)
                }
            })
        })
    }
    
    func update(listInput: List, _ handler: ProviderResult<List> -> ()) {
        
        // TODO db update
        
        self.remoteListProvider.update(listInput) {remoteResult in
            if let remoteList = remoteResult.successResult {
                let list = ListMapper.ListWithRemote(remoteList)
                let result = ProviderResult(status: .Success, sucessResult: list)
                handler(result)
                
            } else {
                
                // TODO when db update implemented
//                print("Error: updating list: \(remoteResult.status)")
//                DefaultRemoteErrorHandler.handle(remoteResult.status, handler: handler)
                
                let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status)
                handler(ProviderResult(status: providerStatus))
                
            }
        }
    }

    func users(list: List, _ handler: ProviderResult<[SharedUser]> -> ()) {
        // TODO
        let user1 = SharedUser(email: "foo@bar.com")
        let user2 = SharedUser(email: "bla@bla.de")
        let result = ProviderResult(status: .Success, sucessResult: [user1, user2])
        
        handler(result)
    }
    
    // TODO probably it doesn't make sense to use this, we have 1. service to verify the email exists, 2. service to update the whole list
    func addUserToList(list: List, email: String, _ handler: ProviderResult<SharedUser> -> ()) {
        // TODO
        let addedUser = SharedUser(email: email)
        let result = ProviderResult(status: .Success, sucessResult: addedUser)
        
        handler(result)
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
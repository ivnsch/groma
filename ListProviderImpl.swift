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
        self.remoteListProvider.add(list, handler: {remoteResult in
            
            if let remoteList = remoteResult.successResult {
                
                let list = ListMapper.ListWithRemote(remoteList)
                
                self.dbProvider.saveList(list, handler: {saved in
                    handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: list))
                })
                
            } else {
                print("error adding the remote list: \(remoteResult)")
                let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status)
                handler(ProviderResult(status: providerStatus))
            }
        })
    }
    
    func update(listInput: List, _ handler: ProviderResult<List> -> ()) {
        
        self.remoteListProvider.update(listInput) {remoteResult in
            if let remoteList = remoteResult.successResult {
                let list = ListMapper.ListWithRemote(remoteList)
                let result = ProviderResult(status: .Success, sucessResult: list)
                handler(result)
                
            } else {
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
    
    
    

}

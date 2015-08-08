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
    
//    
//    // https://gist.github.com/algal/62131fa44ec205a62826
//    func groupBy<T>(equivalent:(a:T, b:T)->Bool, items:[T]) -> [[T]] {
//        var lastItem:T? = nil
//        var groups:[[T]] = []
//        var currentGroup:[T] = []
//        for item in items {
//            if lastItem == nil {
//                // first item
//                currentGroup.append(item)
//            }
//            else {
//                // same kind of item
//                if equivalent(a: item,b: lastItem!) {
//                    currentGroup.append(item)
//                }
//                    // new kind of item
//                else {
//                    // tie off old item
//                    groups.append(currentGroup)
//                    currentGroup = []
//                    currentGroup.append(item)
//                }
//            }
//            lastItem = item
//        }
//        // tie off last group
//        groups.append(currentGroup)
//        
//        return groups
//    }
//    
    func syncListsWithListItems(handler: (ProviderResult<[Any]> -> ())) {
        
        self.dbProvider.loadLists {dbLists in
            
            self.dbProvider.loadAllListItems {dbListItems in
                
                let lists = SyncUtils.toSyncLists(dbLists)
                
                
//                // TODO send only items that are new or updated, currently sending everything
//                // new -> doesn't have lastServerUpdate, updated -> lastUpdate > lastServerUpdate
//                var lists: [List] = []
//                var toRemove: [List] = []
//                for list in dbLists {
//                    if list.removed {
//                        toRemove.append(list)
//                    } else {
//                        // Send only "dirty" items
//                        // Note assumption - lastUpdate can't be smaller than lastServerUpdate, so with != we mean >
//                        // when we receive sync result we reset lastUpdate of all items to lastServerUpdate, from there on lastUpdate can become only bigger
//                        // and when the items are not synced yet, lastServerUpdate is nil so != will also be true
//                        // Note also that the server can handle not-dirty items, we filter them just to reduce the payload
//                        if list.lastUpdate != list.lastServerUpdate {
//                            lists.append(list)
//                        }
//                    }
//                }
                
                
//                // Group by list. Note we do this in tuples and using list in outer loop to preserve the order of the lists
//                var listsWithItems = Array<(List, [ListItem])>()
//                for dbList in dbLists {
//                    var listListItems = [ListItem]()
//                    for dbListItem in dbListItems {
//                        if dbListItem.list == dbList {
//                            listListItems.append(dbListItem)
////                            dbListItems.removeAtIndex(i) // TODO remove the elements to save iterations
//                        }
//                    }
//                    listsWithItems.append((dbList, listListItems))
//                }
//
//                
//                
//                dbListItems.map {dbListItem in
//                    dbListItem.list
//                }
//                
                
//                let listsSyncs = ListSync(list: list, listItemsSync: listItemsSync)
                
                let listsSync = SyncUtils.toListsSync(dbLists, dbListItems: dbListItems)

                self.remoteListProvider.syncListsWithListItems(listsSync) {remoteResult in
                    
                    if let syncResult = remoteResult.successResult {
                        
                        
                        
                        
//                        // for now overwrite all. In the future we should do a timestamp check here also for the case that user does an update while the sync service is being called
//                        // since we support background sync, this should not be neglected
//                        let serverInventory = syncResult.items.map{InventoryMapper.dbWithInventory($0)}
//                        self.dbInventoryProvider.overwrite(serverInventory) {success in
//                            if success {
//                                handler(ProviderResult(status: .Success))
//                            } else {
//                                handler(ProviderResult(status: .DatabaseSavingError))
//                            }
//                            return
//                        }
                        
                        
                        
                        
                    } else {
                        let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status)
                        handler(ProviderResult(status: providerStatus))
                    }
                }
            }
            
            
            
            
            

        }
    }

}

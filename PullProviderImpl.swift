//
//  PullProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 08/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

class PullProviderImpl: PullProvider {
    
    let remoteProvider = RemotePullProvider()
    let listItemsDbProvider = RealmListItemProvider()
    let productsDbProvider = RealmProductProvider()
    
    func pullListProducs(_ listUuid: String, srcUser: SharedUser, _ handler: @escaping (ProviderResult<[ListItem]>) -> Void) {
        
        remoteProvider.pullListProducs(listUuid, srcUser: srcUser) {[weak self] remoteResult in
            
            if let remoteListItems = remoteResult.successResult {
                
                let listItemsWithRelations: ListItemsWithRelations = ListItemMapper.listItemsWithRemote(remoteListItems, sortOrderByStatus: nil)

                self?.listItemsDbProvider.overwrite(listItemsWithRelations.listItems, listUuid: listUuid, clearTombstones: true) {saved in
                    Providers.listItemsProvider.invalidateMemCache() // normally we expect pull to be called outside the list items screen so this is basically a no-op (list items screen clears the mem cache when leaving it). But just to be consistent.
                    
                    handler(ProviderResult(status: .success, sucessResult: listItemsWithRelations.listItems))
                }
                
            } else {
                DefaultRemoteErrorHandler.handleRemoteOnlyCall(remoteResult, handler: handler)
            }
        }
    }
    
    func pullInventoryProducs(_ listUuid: String, srcUser: SharedUser, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        
        remoteProvider.pullInventoryProducs(listUuid, srcUser: srcUser) {[weak self] remoteResult in
            
            if let remoteProducts = remoteResult.successResult {
                
                let dbProducts: [DBProduct] = ProductMapper.dbListItemsWithRemote(remoteProducts)
                
                // TODO!!!! overwrite the categories also
                self?.productsDbProvider.overwriteProducts(dbProducts, clearTombstones: true) {saved in
                    Providers.listItemsProvider.invalidateMemCache()
                    Providers.inventoryItemsProvider.invalidateMemCache()
                    
                    handler(ProviderResult(status: .success))
                }
                
            } else {
                DefaultRemoteErrorHandler.handleRemoteOnlyCall(remoteResult, handler: handler)
            }
        }
    }
}

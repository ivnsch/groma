//
//  InventoryProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class InventoryProviderImpl: InventoryProvider {
   
    let remoteInventoryProvider = RemoteInventoryProvider()
    let dbInventoryProvider = RealmInventoryProvider()

    func inventory(handler: ProviderResult<[InventoryItem]> -> ()) {
        
        self.dbInventoryProvider.loadInventory{dbInventoryItems in
            let mappedDBItems = dbInventoryItems.map{InventoryItemMapper.inventoryItemWithDB($0)}
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: mappedDBItems))
            
            self.remoteInventoryProvider.inventoryItems {remoteResult in
                
                if let remoteInventoryItems = remoteResult.successResult {
                    let inventoryItems: [InventoryItem] = remoteInventoryItems.map{InventoryItemMapper.inventoryItemWithRemote($0)}
                    
                    // if there's no cached list or there's a difference, overwrite the cached list
                    if (mappedDBItems != inventoryItems) {
                        self.dbInventoryProvider.saveInventory(inventoryItems) {saved in
                            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: inventoryItems))
                        }
                    }
                    
                } else {
                    let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status)
                    handler(ProviderResult(status: providerStatus))
                }
            }
        }
    }
    
    func addToInventory(items: [InventoryItem], handler: ProviderResult<Any> -> ()) {
        
        self.remoteInventoryProvider.addToInventory(items) {remoteResult in
            
            if let remoteListItem = remoteResult.successResult {
                self.dbInventoryProvider.saveInventory(items) {saved in
                    let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status) // return status of remote, for now we don't consider save to db critical - TODO review when focusing on offline mode - in this case at least we have to skip the remote call and db operation is critical
                    handler(ProviderResult(status: providerStatus))
                }
                
            } else {
                let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status)
                handler(ProviderResult(status: providerStatus))
            }
        }
    }
 
    func updateInventoryItem(item: InventoryItem) {
        // TODO
//        self.cdProvider.updateInventoryItem(item, handler: {try in
//        })
    }
}

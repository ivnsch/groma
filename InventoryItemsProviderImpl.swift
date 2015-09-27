//
//  InventoryItemsProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class InventoryItemsProviderImpl: InventoryItemsProvider {
   
    let remoteInventoryItemsProvider = RemoteInventoryItemsProvider()
    let dbInventoryProvider = RealmInventoryProvider()

    func inventoryItems(inventory: Inventory, _ handler: ProviderResult<[InventoryItem]> -> ()) {
    
        self.dbInventoryProvider.loadInventory{dbInventoryItems in
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbInventoryItems))
            
            self.remoteInventoryItemsProvider.inventoryItems(inventory) {remoteResult in
                
                if let remoteInventoryItems = remoteResult.successResult {
                    let inventoryItems: [InventoryItem] = remoteInventoryItems.map{InventoryItemMapper.inventoryItemWithRemote($0, inventory: inventory)}
                    
                    // if there's no cached list or there's a difference, overwrite the cached list
                    if (dbInventoryItems != inventoryItems) {
                        self.dbInventoryProvider.saveInventoryItems(inventoryItems) {saved in
                            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: inventoryItems))
                        }
                    }
                    
                } else {
                    DefaultRemoteErrorHandler.handle(remoteResult.status, handler: handler)
                }
            }
        }
    }
    
    func addToInventory(inventory: Inventory, items: [InventoryItemWithHistoryEntry], _ handler: ProviderResult<Any> -> ()) {
        
        self.dbInventoryProvider.add(items) {saved in
            
            if saved {
                handler(ProviderResult(status: .Success))
                
                self.remoteInventoryItemsProvider.addToInventory(inventory, inventoryItems: items) {remoteResult in
                    
                    if let _ = remoteResult.successResult {
                        
                        print("DEBUG: add remote inventory items success")
                        
                        
                        // TODO is this comment still relevant?
                        // For now no saving in local database, since there's no logic to increment in the client
                        // TODO in the future we should do the increment in the client, as the app can be used offline-only
                        // then call a sync with the server when we're online, where we either send the pending increments or somehow overwrite with updated items, taking into account timestamps
                        // remember that the inventory has to support merge since it can be shared with other users
                        //                self.dbInventoryProvider.saveInventory(items) {saved in
                        //                    let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status) // return status of remote, for now we don't consider save to db critical - TODO review when focusing on offline mode - in this case at least we have to skip the remote call and db operation is critical
                        //                    handler(ProviderResult(status: providerStatus))
                        //                }
                        
                        
                        
                    } else {
                        print("Error addToInventory: \(remoteResult.status)")
                        // (what do we do with server invalid data error? do we remove the record from the client's database? which kind of error do we show to the client!? in any case this has to be sent to error monitoring, very clearly and detailed
                        DefaultRemoteErrorHandler.handle(remoteResult.status, handler: handler)
                    }
                }
                
            } else {
                handler(ProviderResult(status: .DatabaseSavingError))
            }
        }
    }
 
    func incrementInventoryItem(item: InventoryItem, delta: Int, _ handler: ProviderResult<Any> -> ()) {
        dbInventoryProvider.incrementInventoryItem(item, delta: delta) {[weak self] saved in
            if saved {
                handler(ProviderResult(status: .Success))

                self?.remoteInventoryItemsProvider.incrementInventoryItem(item, delta: delta) {remoteResult in
                    if !remoteResult.success {
                        print("Error incrementing item in remote")
                        DefaultRemoteErrorHandler.handle(remoteResult.status, handler: handler)                        
                    }
                }
            }
        }
    }
    
    func updateInventoryItem(inventory: Inventory, item: InventoryItem) {
        // TODO
//        self.cdProvider.updateInventoryItem(item, handler: {try in
//        })
    }
}

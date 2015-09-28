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
            
            print("loaded inventoryitems: \(dbInventoryItems)")
            
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
 
    // For now db only query
    private func findInventoryItem(item: InventoryItem, _ handler: ProviderResult<InventoryItem> -> ()) {
        dbInventoryProvider.findInventoryItem(item) {inventoryItemMaybe in
            if let inventoryItem = inventoryItemMaybe {
                handler(ProviderResult(status: .Success, sucessResult: inventoryItem))
            } else {
                handler(ProviderResult(status: .NotFound))
            }
        }
    }
    
    
    
    
    func incrementInventoryItem(item: InventoryItem, delta: Int, _ handler: ProviderResult<Any> -> ()) {
        
        // Get item from database with updated quantityDelta
        // The reason we do this instead of using the item parameter, is that later doesn't always have valid quantityDelta
        // -> When item is incremented we set back quantityDelta after the server's response, this is NOT communicated to the item in the view controller (so on next increment, the passed quantityDelta is invalid)
        // Which is ok. because the UI must not have logic related with background server update
        // Cleaner would be to create a lightweight InventoryItem version for the UI - without quantityDelta, etc. But this adds extra complexity
        
        dbInventoryProvider.incrementInventoryItem(item, delta: delta, onlyDelta: false) {[weak self] saved in
            
            handler(ProviderResult(status: .Success))
            
//            print("SAVED DB \(item)(+delta) in local db. now going to update remote")
            
            self?.remoteInventoryItemsProvider.incrementInventoryItem(item, delta: delta) {remoteResult in
                
                if remoteResult.success {
                    
//                    print("SAVED REMOTE will revert delta now in local db for \(item.product.name), with delta: \(-delta)")
                    
                    // Now that the item was updated in server, set back delta in local database
                    // Note we subtract instead of set to 0, to handle possible parallel requests correctly
                    self?.dbInventoryProvider.incrementInventoryItem(item, delta: -delta, onlyDelta: true) {saved in
                        
                        if saved {
//                            self?.findInventoryItem(item) {result in
//                                if let newitem = result.sucessResult {
//                                    print("3. CONFIRM incremented item: \(item) + \(delta) == \(newitem)")
//                                }
//                            }
                            
                        } else {
                            print("Error: couln't save remote inventory item")
                        }
                        
                    }
                    
                } else {
                    DefaultRemoteErrorHandler.handle(remoteResult.status, handler: handler)
                    print("Error incrementing item in remote")
                }
            }
        }
    }
    
    func updateInventoryItem(inventory: Inventory, item: InventoryItem) {
        // TODO
//        self.cdProvider.updateInventoryItem(item, handler: {try in
//        })
    }
    
    func removeInventoryItem(item: InventoryItem, _ handler: ProviderResult<Any> -> ()) {
        dbInventoryProvider.removeInventoryItem(item) {saved in
            handler(ProviderResult(status: .Success))
        }
    }
}

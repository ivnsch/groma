//
//  InventoryProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class InventoryProviderImpl: InventoryProvider {
   
    private let remoteProvider = RemoteInventoryProvider()
    
    func inventories(handler: ProviderResult<[Inventory]> -> ()) {
        self.remoteProvider.inventories {remoteResult in
            if let remoteInventories = remoteResult.successResult {
                let inventories = remoteInventories.map{InventoryMapper.inventoryWithRemote($0)}
                handler(ProviderResult(status: .Success, sucessResult: inventories))
                
            } else {
                let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status)
                handler(ProviderResult(status: providerStatus))
            }
        }
    }
    
    func addInventory(inventory: InventoryInput, _ handler: ProviderResult<Any> -> ()) {
        self.remoteProvider.addInventory(inventory) {remoteResult in
            let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status)
            handler(ProviderResult(status: providerStatus))
        }
    }
    
    func updateInventory(inventory: InventoryInput, _ handler: ProviderResult<Any> -> ()) {
        self.remoteProvider.updateInventory(inventory) {remoteResult in
            let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status)
            handler(ProviderResult(status: providerStatus))
        }
    }
}

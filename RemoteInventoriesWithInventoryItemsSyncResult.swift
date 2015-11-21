//
//  RemoteInventoriesWithInventoryItemsSyncResult.swift
//  shoppin
//
//  Created by ischuetz on 09/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteInventoryItemsSyncResult: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let inventoryUuid: String
    let inventoryItems: [RemoteInventoryItemWithProduct]
//    let couldNotUpdate: [String]
    let couldNotDelete: [String]
    
    init(inventoryUuid: String, inventoryItems: [RemoteInventoryItemWithProduct]/*, couldNotUpdate: [String]*/, couldNotDelete: [String]) {
        self.inventoryUuid = inventoryUuid
        self.inventoryItems = inventoryItems
//        self.couldNotUpdate = couldNotUpdate
        self.couldNotDelete = couldNotDelete
    }
    
    init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.inventoryUuid = representation.valueForKeyPath("inventoryUuid") as! String
        
        let inventoryItems = representation.valueForKeyPath("inventoryItems") as! [AnyObject]
        self.inventoryItems = RemoteInventoryItemWithProduct.collection(response: response, representation: inventoryItems)
        
//        self.couldNotUpdate = representation.valueForKeyPath("couldNotUpdate") as! [String]
        self.couldNotDelete = representation.valueForKeyPath("couldNotDelete") as! [String]
    }
    
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteInventoryItemsSyncResult] {
        var inventoryItemsSyncResult = [RemoteInventoryItemsSyncResult]()
        for obj in representation as! [AnyObject] {
            if let inventoryItem = RemoteInventoryItemsSyncResult(response: response, representation: obj) {
                inventoryItemsSyncResult.append(inventoryItem)
            }
            
        }
        return inventoryItemsSyncResult
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) inventoryUuid: \(self.inventoryUuid), inventoryItems: \(self.inventoryItems), couldNotDelete: \(self.couldNotDelete)}"
    }
}


final class RemoteInventoriesWithInventoryItemsSyncResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    let inventories: [RemoteInventory]
    let couldNotUpdate: [String]
    let couldNotDelete: [String]
    let inventoryItemsSyncResults: [RemoteInventoryItemsSyncResult]
    
    init(inventories: [RemoteInventory], couldNotUpdate: [String], couldNotDelete: [String], inventoryItemsSyncResults: [RemoteInventoryItemsSyncResult]) {
        self.inventories = inventories
        self.couldNotUpdate = couldNotUpdate
        self.couldNotDelete = couldNotDelete
        self.inventoryItemsSyncResults = inventoryItemsSyncResults
    }
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        let inventories = representation.valueForKeyPath("inventories") as! [AnyObject]
        self.inventories = RemoteInventory.collection(response: response, representation: inventories)
        
        self.couldNotUpdate = representation.valueForKeyPath("couldNotUpdate") as! [String]
        self.couldNotDelete = representation.valueForKeyPath("couldNotDelete") as! [String]
        
        let inventoryItemsSyncResults = representation.valueForKeyPath("inventoryItems") as! [AnyObject]
        self.inventoryItemsSyncResults = RemoteInventoryItemsSyncResult.collection(response: response, representation: inventoryItemsSyncResults)
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) inventories: \(self.inventories), couldNotUpdate: \(self.couldNotUpdate), couldNotDelete: \(self.couldNotDelete), inventoryItemsSyncResults: \(self.inventoryItemsSyncResults)}"
    }
}
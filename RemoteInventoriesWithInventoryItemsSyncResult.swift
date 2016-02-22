//
//  RemoteInventoriesWithInventoryItemsSyncResult.swift
//  shoppin
//
//  Created by ischuetz on 09/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteInventoryItemsSyncResult: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
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
    
    init?(representation: AnyObject) {
        guard
            let inventoryUuid = representation.valueForKeyPath("inventoryUuid") as? String,
            let inventoryItemsObj = representation.valueForKeyPath("inventoryItems") as? [AnyObject],
            let inventoryItems = RemoteInventoryItemWithProduct.collection(inventoryItemsObj),
            let couldNotDelete = representation.valueForKeyPath("couldNotDelete") as? [String]
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.inventoryUuid = inventoryUuid
        self.inventoryItems = inventoryItems
//        self.couldNotUpdate = representation.valueForKeyPath("couldNotUpdate") as! [String]
        self.couldNotDelete = couldNotDelete
    }
    
    static func collection(representation: AnyObject) -> [RemoteInventoryItemsSyncResult]? {
        var inventoryItemsSyncResult = [RemoteInventoryItemsSyncResult]()
        for obj in representation as! [AnyObject] {
            if let inventoryItem = RemoteInventoryItemsSyncResult(representation: obj) {
                inventoryItemsSyncResult.append(inventoryItem)
            } else {
                return nil
            }
            
        }
        return inventoryItemsSyncResult
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) inventoryUuid: \(self.inventoryUuid), inventoryItems: \(self.inventoryItems), couldNotDelete: \(self.couldNotDelete)}"
    }
}


struct RemoteInventoriesWithInventoryItemsSyncResult: ResponseObjectSerializable, CustomDebugStringConvertible {
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
    
    init?(representation: AnyObject) {
        guard
            let inventoriesObj = representation.valueForKeyPath("inventories") as? [AnyObject],
            let inventories = RemoteInventory.collection(inventoriesObj),
            let couldNotUpdate = representation.valueForKeyPath("couldNotUpdate") as? [String],
            let couldNotDelete = representation.valueForKeyPath("couldNotDelete") as? [String],
            let inventoryItemsSyncResultsObj = representation.valueForKeyPath("inventoryItems") as? [AnyObject],
            let inventoryItemsSyncResults = RemoteInventoryItemsSyncResult.collection(inventoryItemsSyncResultsObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.inventories = inventories
        self.couldNotUpdate = couldNotUpdate
        self.couldNotDelete = couldNotDelete
        self.inventoryItemsSyncResults = inventoryItemsSyncResults
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) inventories: \(inventories), couldNotUpdate: \(couldNotUpdate), couldNotDelete: \(couldNotDelete), inventoryItemsSyncResults: \(inventoryItemsSyncResults)}"
    }
}
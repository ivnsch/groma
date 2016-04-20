//
//  RemoteInventoryWithDependencies.swift
//  shoppin
//
//  Created by ischuetz on 20/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteInventoryWithDependencies: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let inventory: RemoteInventory
    let users: [RemoteSharedUser]
    
    init?(representation: AnyObject) {
        guard
            let inventoryObj = representation.valueForKeyPath("inventory"),
            let inventory = RemoteInventory(representation: inventoryObj),
            let unserializedUsers = representation.valueForKeyPath("users"),
            let users = RemoteSharedUser.collection(unserializedUsers)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.inventory = inventory
        self.users = users
    }
    
    static func collection(representation: AnyObject) -> [RemoteInventoryWithDependencies]? {
        var inventories = [RemoteInventoryWithDependencies]()
        for obj in representation as! [AnyObject] {
            if let inventory = RemoteInventoryWithDependencies(representation: obj) {
                inventories.append(inventory)
            } else {
                return nil
            }
            
        }
        return inventories
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) inventory: \(inventory), users: \(users)}"
    }
}
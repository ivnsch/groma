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
            let inventoryObj = representation.value(forKeyPath: "inventory"),
            let inventory = RemoteInventory(representation: inventoryObj as AnyObject),
            let unserializedUsers = representation.value(forKeyPath: "users") as? [AnyObject],
            let users = RemoteSharedUser.collection(unserializedUsers)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.inventory = inventory
        self.users = users
    }
    
    static func collection(_ representation: [AnyObject]) -> [RemoteInventoryWithDependencies]? {
        var inventories = [RemoteInventoryWithDependencies]()
        for obj in representation {
            if let inventory = RemoteInventoryWithDependencies(representation: obj) {
                inventories.append(inventory)
            } else {
                return nil
            }
            
        }
        return inventories
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) inventory: \(inventory), users: \(users)}"
    }
}

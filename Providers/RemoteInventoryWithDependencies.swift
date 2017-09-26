//
//  RemoteInventoryWithDependencies.swift
//  shoppin
//
//  Created by ischuetz on 20/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation


public struct RemoteInventoryWithDependencies: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    public let inventory: RemoteInventory
    public let users: [RemoteSharedUser]
    
    public init?(representation: AnyObject) {
        guard
            let inventoryObj = representation.value(forKeyPath: "inventory"),
            let inventory = RemoteInventory(representation: inventoryObj as AnyObject),
            let unserializedUsers = representation.value(forKeyPath: "users") as? [AnyObject],
            let users = RemoteSharedUser.collection(unserializedUsers)
            else {
                logger.e("Invalid json: \(representation)")
                return nil}
        
        self.inventory = inventory
        self.users = users
    }
    
    public static func collection(_ representation: [AnyObject]) -> [RemoteInventoryWithDependencies]? {
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
    
    public var debugDescription: String {
        return "{\(type(of: self)) inventory: \(inventory), users: \(users)}"
    }
}

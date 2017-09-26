//
//  RemoteInventoryWithItems.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation


public struct RemoteInventoryWithItems: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    
    public let inventory: RemoteInventory
    public let inventoryItems: RemoteInventoryItemsWithDependenciesNoInventory
    
    public init?(representation: AnyObject) {
        guard
            let inventoryObj = representation.value(forKeyPath: "inventory"),
            let inventory = RemoteInventory(representation: inventoryObj as AnyObject),
            let itemsObj = representation.value(forKeyPath: "items") as? [AnyObject],
            let inventoryItems = RemoteInventoryItemsWithDependenciesNoInventory(representation: itemsObj as AnyObject)
            else {
                logger.e("Invalid json: \(representation)")
                return nil}
        
        self.inventory = inventory
        self.inventoryItems = inventoryItems
    }
    
    public static func collection(_ representation: [AnyObject]) -> [RemoteInventoryWithItems]? {
        var listItems = [RemoteInventoryWithItems]()
        for obj in representation {
            if let listItem = RemoteInventoryWithItems(representation: obj) {
                listItems.append(listItem)
            } else {
                return nil
            }
            
        }
        return listItems
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) inventory: \(inventory), inventoryItems: [\(inventoryItems)]}"
    }
}
